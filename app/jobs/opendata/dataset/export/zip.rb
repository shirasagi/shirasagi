class Opendata::Dataset::Export::Zip
  extend ActiveSupport::Concern

  attr_accessor :output_dir

  def initialize(path)
    @path = path
  end

  def compress
    FileUtils.rm(@path) if File.exist?(@path)
    Zip::File.open(@path, Zip::File::CREATE) do |zip|
      add_csv(zip)
    end
  end

  def add_csv(zip)
    Dir.glob("#{@output_dir}/**/*").each do |file|
      name = file.gsub("#{@output_dir}/", "")
      name = ::Fs.zip_safe_path(name)
      zip.add(name, file)
    end
  end
end
