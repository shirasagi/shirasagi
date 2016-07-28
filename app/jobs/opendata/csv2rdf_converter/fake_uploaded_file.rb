class Opendata::Csv2rdfConverter::FakeUploadedFile
  extend Forwardable

  # The basename of the file in the client.
  attr_accessor :original_filename

  # A string with the MIME type of the file.
  attr_accessor :content_type

  # A +Tempfile+ object with the actual uploaded file. Note that some of
  # its interface is available directly.
  attr_accessor :tempfile
  alias_attribute :to_io, :tempfile

  # A string with the headers of the multipart request.
  attr_accessor :headers

  def initialize(tempfile, content_type)
    @tempfile = tempfile
    @original_filename = ::File.basename(tempfile.path)
    @original_filename &&= @original_filename.encode "UTF-8"
    @content_type = content_type
    @headers = nil
  end

  def_delegators :@tempfile, :read, :open, :path, :rewind, :size, :eof?

  def close(unlink_now = false)
  end
end
