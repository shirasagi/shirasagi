module Cms::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    DEFAULT_IMG_SRC = "/assets/img/dummy.png".freeze

    included do
      field :html, type: String
      field :markdown, type: String
      field :contains_urls, type: Array, default: []
      field :value_contains_urls, type: Array, default: []
      permit_params :html, :markdown

      before_validation :set_contains_urls

      if respond_to?(:template_variable_handler)
        template_variable_handler('img.src', :template_variable_handler_img_src)
        template_variable_handler('thumb.src', :template_variable_handler_thumb_src)
      end

      if respond_to?(:liquidize)
        liquidize do
          export as: :html do |context|
            next html if !respond_to?(:form) || form.blank?
            copy = context.registers.dup
            copy.delete(:preview)
            form.render_html(self, copy)
          end
        end
      end
    end

    def html
      if SS.config.cms.html_editor == "markdown"
        Kramdown::Document.new(markdown.to_s, input: 'GFM').to_html
      else
        self[:html]
      end
    end

    def mobile_size_enable?
      self.site.mobile_enabled?
    end

    def mobile_size
      self.site.mobile_size
    end

    private

    def set_contains_urls
      if html.blank?
        self.contains_urls = []
      else
        self.contains_urls = html.scan(/(?:href|src)="(.*?)"/).flatten.uniq
      end
    end

    def template_variable_handler_img_src(name, issuer)
      extract_img_src(html) || default_img_src
    end

    def template_variable_handler_thumb_src(name, issuer)
      thumb_path || extract_img_src(html) || default_img_src
    end

    def default_img_src
      ERB::Util.html_escape(DEFAULT_IMG_SRC)
    end

    def extract_img_src(html)
      ::SS::Html.extract_img_src(html, respond_to?(:url) ? url : nil)
    end

    def thumb_path
      "/fs/#{thumb.id}/#{thumb.filename}" if thumb.present?
    end
  end
end
