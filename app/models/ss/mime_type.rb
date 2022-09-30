require "mime/types"

class SS::MimeType
  DEFAULT_MIME_TYPE = "application/octet-stream".freeze
  SVG_MIME_TYPE = "image/svg+xml".freeze

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
      return false if content_type == SVG_MIME_TYPE
      true
    end
  end
end
