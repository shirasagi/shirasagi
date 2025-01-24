require 'mail'
require 'mail/field'
require 'mail/field_list'

module Mail
  class Field
    alias parse_field_without_shirasagi parse_field

    def parse_field(name, value, charset)
      if !value.is_a?(Array)
        value = value.to_s
        if value.encoding == Encoding::ASCII_8BIT
          value = ::Mail::Encodings.transcode_charset(value, value.encoding, charset || 'UTF-8')
        end
      end

      parse_field_without_shirasagi(name, value, charset)
    end
  end
end
