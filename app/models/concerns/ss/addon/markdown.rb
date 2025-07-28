module SS::Addon
  module Markdown
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :text, type: String
      field :text_type, type: String
      permit_params :text, :text_type
    end

    module ClassMethods
      def text_type_options
        [:plain, :cke, :markdown].map { |m| [I18n.t("ss.options.text_type.#{m}"), m] }
      end
    end

    delegate :text_type_options, to: :class

    def html(**options)
      return nil if text.blank?

      text = self.text
      if options.key?(:truncate)
        text = text.truncate(options[:truncate], options.slice(:separator, :omission))
      end

      case text_type
      when 'markdown'
        SS::Addon::Markdown.text_to_html(
          text, auto_link: options.fetch(:auto_link, true), sanitize: options.fetch(:sanitize, true))
      when 'cke'
        if options.fetch(:sanitize, true)
          text = ApplicationController.helpers.sanitize(text)
        end
        "<div class=\"ss-cke\">#{text}</div>".html_safe
      else
        if options.fetch(:auto_link, true)
          text = SS::Addon::Markdown.auto_link(text, sanitize: options.fetch(:sanitize, true))
        else
          if options.fetch(:sanitize, true)
            text = ApplicationController.helpers.sanitize(text)
          end
          text = ERB::Util.h(text)
        end
        text = text.gsub(/\R/, "<br />")
        text = "<p>#{text}</p>"
        text.html_safe
      end
    end

    def summary_text(limit = 80)
      text = self.text
      text = ApplicationController.helpers.strip_tags(text) if text_type == 'cke'
      text = text.squish.truncate(limit) if limit
      text
    end

    class << self
      def text_to_html(text, auto_link: true, sanitize: true)
        return nil if text.blank?

        text = text.join("\n") if text.is_a?(Array)
        html = Kramdown::Document.new(text.to_s, input: 'GFM').to_html
        if auto_link
          html = SS::Addon::Markdown.auto_link(html, sanitize: sanitize)
        end
        if sanitize
          html = ApplicationController.helpers.sanitize(html)
        end
        html.strip.html_safe
      end

      def auto_link(text, sanitize: true)
        ApplicationController.helpers.ss_auto_link(
          text, link: :urls, sanitize: sanitize, link_to: SS::Addon::Markdown.method(:markdown_link_to))
      end

      def markdown_link_to(link_text, attributes, escapes)
        href = attributes["href"]
        if escapes
          # '&' が '&amp;' にエスケープされているが、リンクとしては不適切なため、元に戻す
          href = CGI.unescapeHTML(href)
        end
        if href.present? && !Sys::TrustedUrlValidator.trusted_url?(href)
          attributes["href"] = Rails.application.routes.url_helpers.sns_redirect_path(ref: href)
        end
        attributes["data-controller"] = "ss--open-external-link-in-new-tab"
        attributes["data-href"] = href
        ApplicationController.helpers.content_tag(:a, link_text, attributes, escapes)
      end
    end
  end
end
