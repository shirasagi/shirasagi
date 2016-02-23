class SS::FilenameConvertor
  class << self
    def convert(filename, opts = {})
      id = opts[:id]
      return filename unless filename =~ /[^\w\-\.]/

      case SS.config.env.multibyte_filename
      when "sequence"
        "#{id}#{::File.extname(filename)}"
      when "underscore"
        filename.gsub(/[^\w\-\.]/, "_")
      else
        filename
      end
    end
  end
end
