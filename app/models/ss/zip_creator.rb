class SS::ZipCreator
  include ActiveModel::Model
  include SS::ExportHelper

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
    create_entry(sanitize_filename(file.name)) do |f|
      ::IO.copy_stream(file.path, f)
    end
  end

  def create_entry(entry_name, &block)
    zip.get_output_stream(sjis_clean(entry_name), &block)
  end

  def close
    return if @zip.nil?

    @zip.close
    @zip = nil

    ::FileUtils.rm_f(@path)
    ::FileUtils.mv(@tmp_path, @path)

    ::Zip.write_zip64_support = @save_write_zip64_support if !@save_write_zip64_support.nil?
    ::Zip.unicode_names = @save_unicode_names if !@save_unicode_names.nil?
  end

  private

  def zip
    @zip ||= begin
      @save_write_zip64_support = Zip.write_zip64_support
      @save_unicode_names = Zip.unicode_names
      ::Zip.write_zip64_support = true
      ::Zip.unicode_names = true

      ::FileUtils.mkdir_p(File.dirname(@tmp_path))
      ::FileUtils.rm_rf(@tmp_path)
      ::Zip::File.open(@tmp_path, Zip::File::CREATE)
    end
  end

  def sjis_clean(name)
    return name if name.blank?

    name.encode('cp932', invalid: :replace, undef: :replace, replace: "_").encode("UTF-8")
  end
end
