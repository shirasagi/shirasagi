class Opendata::Csv2rdfConverter::FakeUploadedFile < ActionDispatch::Http::UploadedFile
  def initialize(filename, content_type)
    super(tempfile: ::File.open(filename, "r:utf-8"), filename: ::File.basename(filename), type: content_type)
    def @tempfile.delete
      # protected from file deletion
    end
  end

  def close(unlink_now = false)
    @tempfile.close
  end
end
