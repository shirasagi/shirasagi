module SS::Addon
  module Markdown
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :text, type: String
      field :text_type, type: String
      permit_params :text, :text_type
    end

    def text_type_options
      [:plain, :markdown].map { |m| [I18n.t("ss.options.text_type.#{m}"), m] }
    end

    def html
      return nil if text.blank?
      if text_type == 'markdown'
        SS::Addon::Markdown.text_to_html(text)
      else
        ERB::Util.h(text).gsub(/(\r\n?)|(\n)/, "<br />").html_safe
      end
    end

    class << self
      def text_to_html(text)
        return nil if text.blank?
        ApplicationController.helpers.sanitize(Kramdown::Document.new(text, input: 'GFM').to_html)
      end
    end
  end
end
