module Fs
  class UploadedFile < ::Tempfile
    attr_accessor :original_filename, :content_type

    def self.create_from_file(file, basename: "ss_file", filename: nil, content_type: nil)
      path = file.try(:path) || file.to_s
      instance = self.new(basename)
      instance.binmode
      instance.write(::File.binread(path))
      instance.rewind
      instance.original_filename = filename.presence || ::File.basename(path)
      instance.content_type = content_type || ::Fs.content_type(path)

      return instance unless block_given?

      begin
        return yield instance
      ensure
        instance.close unless instance.closed?
      end
    end
  end
end
