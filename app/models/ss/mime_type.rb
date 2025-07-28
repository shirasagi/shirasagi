require "mime/types"

class SS::MimeType
  DEFAULT_MIME_TYPE = "application/octet-stream".freeze
  SVG_MIME_TYPE = "image/svg+xml".freeze
  HTML_MIME_TYPE = "text/html".freeze
  UNSAFE_MIME_TYPES = Set[SVG_MIME_TYPE, HTML_MIME_TYPE].freeze

  class << self
    def find(name, default = nil)
      ret = SS.config.env.mime_type_map[name.sub(/.*\./, "")]
      if ret.blank?
        mime_types = ::MIME::Types.type_for(name)
        ret = mime_types.first.content_type rescue nil if mime_types.present?
      end
      ret.presence || default || DEFAULT_MIME_TYPE
    end

    def safe_for_inline?(content_type)
      return false if UNSAFE_MIME_TYPES.include?(content_type)
      true
    end
  end
end
