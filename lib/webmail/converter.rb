class Webmail::Converter
  class << self
    def extract_address(address)
      Mail::Address.new(address.encode('ascii-8bit', :invalid => :replace, :undef => :replace)).address
    end

    def extract_display_name(address)
      address.gsub(/<?#{extract_address(address)}>?/, "").strip
    end
  end
end
