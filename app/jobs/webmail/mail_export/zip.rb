class Webmail::MailExport::Zip
  extend ActiveSupport::Concern

  attr_accessor :output_dir

  def initialize(path)
    @path = path
  end

  def compress
    FileUtils.rm(@path) if File.exist?(@path)
    Zip::File.open(@path, Zip::File::CREATE) do |zip|
      add_json(zip)
    end
  end

  def add_json(zip)
    Dir.glob("#{@output_dir}/*.eml").each do |file|
      name = ::File.basename(file)
      zip.add(name.encode('cp932', invalid: :replace, undef: :replace, replace: "_"), file)
    end
  end
end
