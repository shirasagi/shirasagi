class Gws::Memo::MessageExport::Zip
  extend ActiveSupport::Concern

  attr_accessor :output_dir, :output_format

  def initialize(path)
    @path = path
  end

  def compress
    FileUtils.rm(@path) if File.exist?(@path)
    Zip::File.open(@path, Zip::File::CREATE) do |zip|
      if @output_format == "json"
        add_json(zip)
      elsif @output_format == "eml"
        add_eml(zip)
      end
    end
  end

  def add_json(zip)
    Dir.glob("#{@output_dir}/*.json").each do |file|
      name = ::File.basename(file)
      zip.add(name.encode('cp932'), file)
    end
  end

  def add_eml(zip)
    Dir.glob("#{@output_dir}/*.eml").each do |file|
      name = ::File.basename(file)
      zip.add(name.encode('cp932'), file)
    end
  end
end
