module Webmail
  extend Sys::ModulePermission

  class CP50221Encoder < Mail::Ruby19::BestEffortCharsetEncoder
    def encode(string, charset)
      if charset.casecmp("iso-2022-jp") == 0
        # treated string as CP50221 (Microsoft Extended Encoding of ISO-2022-JP)
        # NKF.nkf("-w", string)
        string.force_encoding(Encoding::CP50221)
      else
        super
      end
    end
  end

  module_function

  def activate_cp50221
    save = ::Mail::Ruby19.charset_encoder
    ::Mail::Ruby19.charset_encoder = CP50221Encoder.new if save.class != CP50221Encoder

    begin
      yield
    ensure
      ::Mail::Ruby19.charset_encoder = save
    end
  end
end
