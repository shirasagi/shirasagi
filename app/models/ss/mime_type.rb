require "mime/types"

class SS::MimeType
  class << self
    def find(name, default)
      mime_types = ::MIME::Types.type_for(name)
      ret ||= mime_types.first.content_type rescue nil if mime_types.present?
      ret ||= default
      ret
    end
  end
end
