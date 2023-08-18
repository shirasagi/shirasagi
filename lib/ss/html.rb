class SS::Html
  class << self
    def extract_img_src(html, base_url = nil)
      return nil unless html =~ /<\s*?img\s+[^>]*\/?>/i

      img_tag = $&
      return nil unless img_tag =~ /src\s*=\s*(['"]?[^'"]+['"]?)/

      img_source = $1
      img_source = img_source[1..-1] if img_source.start_with?("'", '"')
      img_source = img_source[0..-2] if img_source.end_with?("'", '"')
      img_source = img_source.strip
      if img_source.start_with?('.') && base_url
        # convert relative path to absolute path
        img_source = ::File.dirname(base_url) + '/' + img_source
      end
      img_source
    end
  end
end
