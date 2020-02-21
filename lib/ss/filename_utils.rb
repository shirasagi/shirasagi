class SS::FilenameUtils
  class << self
    def convert(filename, opts = {})
      id = opts[:id]
      return filename unless filename =~ /[^\w\-\.]/

      case SS.config.env.multibyte_filename
      when "sequence"
        "#{id}#{::File.extname(filename)}"
      when "underscore"
        filename.gsub(/[^\w\-\.]/, "_")
      when "hex"
        "#{SecureRandom.hex(16)}#{::File.extname(filename)}"
      else
        filename
      end
    end

    def make_tmpname(prefix = nil, suffix = nil)
      # blow code come from Tmpname::make_tmpname
      "#{prefix}#{Time.now.strftime("%Y%m%d")}-#{$PID}-#{rand(0x100000000).to_s(36)}#{suffix}"
    end
  end
end
