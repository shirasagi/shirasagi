module Sys::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      field :markdown, type: String
      permit_params :html, :markdown

      if respond_to?(:template_variable_handler)
        template_variable_handler('img.src', :template_variable_handler_img_src)
      end
    end

    def html
      if SS.config.cms.html_editor == "markdown"
        Kramdown::Document.new(markdown.to_s, input: 'GFM').to_html
      else
        self[:html]
      end
    end

    private

    def template_variable_handler_img_src(name, issuer)
      extract_img_src(html) || default_img_src
    end

    def default_img_src
      ERB::Util.html_escape("/assets/img/dummy.png")
    end

    def extract_img_src(html)
      return nil unless html =~ /\<\s*?img\s+[^>]*\/?>/i

      img_tag = $&
      return nil unless img_tag =~ /src\s*=\s*(['"]?[^'"]+['"]?)/

      img_source = $1
      img_source = img_source[1..-1] if img_source.start_with?("'", '"')
      img_source = img_source[0..-2] if img_source.end_with?("'", '"')
      img_source = img_source.strip
      img_source
    end
  end
end
