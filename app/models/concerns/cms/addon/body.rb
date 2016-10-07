module Cms::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      field :markdown, type: String
      permit_params :html, :markdown

      validate :check_mobile_html_size

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

      def check_mobile_html_size
        if @cur_site.mobile_enabled?
          if html_size > @cur_site.mobile_size * 1000
            errors.add(:html, I18n.t("errors.messages.too_bigsize"))
          end
        end
      end

      def html_size
        size = 0
        size += self[:html].bytesize
        if self.try(:files)
          size += file_size
        end
        size
      end

      def file_size
        size = 0
        html_files.each do |file|
          size += file.size
        end
        if size > @cur_site.mobile_size * 1000
          errors.add(:files, I18n.t("errors.messages.too_bigsize"))
        end
        size
      end

      def html_files
        in_html_files = []
        file_id_str = self[:html].scan(%r{src=\"/fs/(.+?)/_/})
        ids = []

        file_id_str.each do |src|
          ids << src[0].delete("/").to_i
        end

        self.files.each do |file|
          if ids.include?(file.id)
            in_html_files << file
          end
        end
        in_html_files
      end
  end
end
