require "mime/types"

class SS::MimeType
  DEFAULT_MIME_TYPE = "application/octet-stream".freeze

  class << self
    def find(name, default = nil)
      ret = SS.config.env.mime_type_map[name.sub(/.*\./, "")]
      if ret.blank?
        mime_types = ::MIME::Types.type_for(name)
        ret = mime_types.first.content_type rescue nil if mime_types.present?
      end
      ret.presence || default || DEFAULT_MIME_TYPE
    end
  end
end
