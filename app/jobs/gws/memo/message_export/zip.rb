class Gws::Memo::MessageExport::Zip
  extend ActiveSupport::Concern

  def initialize(path)
    @path = path
    @tmp_path = "#{path}.$$"
    FileUtils.mkdir_p(File.dirname(@path))
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

      ::Zip::File.open(@tmp_path, Zip::File::CREATE)
    end
  end

  def sjis_clean(name)
    return name if name.blank?
    name.encode('cp932', invalid: :replace, undef: :replace, replace: "_").encode("UTF-8")
  end
end
