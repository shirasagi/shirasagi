require 'mail'
require 'mail/field'
require 'mail/field_list'

module Mail
  class Field
    alias new_field_without_shirasagi new_field

    def new_field(name, value, charset)
      if !value.is_a?(Array)
        value = value.to_s
        if value.encoding == Encoding::ASCII_8BIT
          value = ::Mail::Encodings.transcode_charset(value, value.encoding, charset || 'UTF-8')
        end
      end

      new_field_without_shirasagi(name, value, charset)
    end
  end
end
