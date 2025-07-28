class SS::ZipCreator
  include ActiveModel::Model

  attr_reader :cur_site, :cur_user, :file

  delegate :filename, :path, :url, :read, :content_type, to: :file

  def initialize(basename, user, opts = {})
    @cur_site = opts[:cur_site]
    @cur_user = user

    @file = SS::DownloadJobFile.new(user, basename)
    @path = @file.path
    @tmp_path = "#{@path}.$$"
  end

  def add_file(file)
    name = file.name
    name = ::Fs.sanitize_filename(name)
    name = ::Fs.zip_safe_name(name)
    zip.add(name, file.path)
  end

  def create_entry(entry_name, &block)
    entry_name = ::Fs.zip_safe_path(entry_name)
    zip.get_output_stream(entry_name, &block)
  end

  def close
    return if @zip.nil?

    @zip.close
    @zip = nil

    ::FileUtils.rm_f(@path)
    ::FileUtils.mv(@tmp_path, @path)
  end

  private

  def zip
    @zip ||= begin
      ::FileUtils.mkdir_p(File.dirname(@tmp_path))
      ::FileUtils.rm_rf(@tmp_path)
      ::Zip::File.open(@tmp_path, Zip::File::CREATE)
    end
  end
end
