class SS::SvgSanitizer
  class << self
    def sanitize(file_path, content_type:)
      content_type = SS::MimeType.find(file_path) if content_type.blank?
      return false if content_type.casecmp(SS::MimeType::SVG_MIME_TYPE) != 0 || !::Fs.exist?(file_path)

      unsafe_content = ::File.read(file_path)
      return false if unsafe_content.blank?

      if unsafe_content.include?("<?xml") || unsafe_content.include?("<!DOCTYPE")
        sanitizer = Loofah.xml_document(unsafe_content)
      else
        sanitizer = Loofah.xml_fragment(unsafe_content)
      end
      safe_content = sanitizer.scrub!(scrubber).to_s

      Fs.safe_create(file_path) { |f| f.write safe_content }
      true
    end

    private

    def scrubber
      Loofah::Scrubber.new do |node|
        if node.name == "script"
          node.remove
          next
        end
        if node.attributes.present? && node.attributes["onclick"].present?
          node.remove_attribute("onclick")
        end
        if node.attributes.present? && node.attributes["href"].present? && unsafe_href?(node.attributes["href"].value)
          node.remove_attribute("href")
        end
      end
    end

    def safe_href?(href)
      url = ::Addressable::URI.parse(href) rescue nil
      safe_href = true
      if safe_href && url.blank?
        safe_href = false
      end
      if safe_href && url && url.scheme && !UrlValidator::ALLOWED_SCHEMES.include?(url.scheme)
        safe_href = false
      end
      if safe_href && url && !Sys::TrustedUrlValidator.valid_url?(url)
        safe_href = false
      end

      safe_href
    end

    def unsafe_href?(href)
      !safe_href?(href)
    end
  end
end
