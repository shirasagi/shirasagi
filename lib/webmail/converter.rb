class Webmail::Converter
  class << self
    def extract_address(address)
      Mail::Address.new(address.encode('ascii-8bit', :invalid => :replace, :undef => :replace)).address rescue address
    end

    def extract_display_name(address)
      address.gsub(/<?#{extract_address(address)}>?/, "").strip
    end

    def quote_address(address)
      m = address.strip.match(/\A(.+)(<.*?>)\z/)
      m ? %("#{m[1].delete(%('")).strip}" #{m[2]}) : address
    end
  end
end
