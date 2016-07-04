module Member::Addon::Blog
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String, metadata: { unicode: :nfc }
      permit_params :html
      validates :html, presence: true

      if respond_to?(:template_variable_handler)
        template_variable_handler('img.src', :template_variable_handler_img_src)
      end
    end

    def summary
      #return summary_html if summary_html.present?
      return "" unless html.present?
      ApplicationController.helpers.sanitize(html, tags: []).squish.truncate(120)
    end

    def template_variable_handler_img_src(name, issuer)
      dummy_source = ERB::Util.html_escape("/assets/img/dummy.png")

      return dummy_source unless html =~ /\<\s*?img\s+[^>]*\/?>/i

      img_tag = $&
      return dummy_source unless img_tag =~ /src\s*=\s*(['"]?[^'"]+['"]?)/

      img_source = $1
      img_source = img_source[1..-1] if img_source.start_with?("'", '"')
      img_source = img_source[0..-2] if img_source.end_with?("'", '"')
      img_source = img_source.strip
      img_source
    end
  end
end
