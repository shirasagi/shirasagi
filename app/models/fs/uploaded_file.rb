module Fs
  class UploadedFile < ::Tempfile
    attr_accessor :original_filename, :content_type
  end
end
