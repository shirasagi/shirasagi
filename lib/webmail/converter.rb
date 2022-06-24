class Webmail::Converter
  class << self
    def extract_address(address)
      begin
        Mail::Address.new(address.encode('ascii-8bit', :invalid => :replace, :undef => :replace)).address
      rescue
        email = address[/<[^@\s]+@(?:[-a-z0-9]+\.)+[a-z]{2,}>/]
        email ? email.delete('<>') : address
      end
    end

    def extract_display_name(address)
      address.gsub(/<?#{extract_address(address)}>?/, "").strip
    end
  end
end
