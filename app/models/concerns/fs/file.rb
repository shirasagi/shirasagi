module Fs::File
  extend ActiveSupport::Concern

  module ClassMethods
    def mode
      :file
    end

    def exist?(path)
      FileTest.exist? path
    end

    def file?(path)
      FileTest.file? path
    end

    def directory?(path)
      FileTest.directory? path
    end

    def read(path)
      ::File.read path
    end

    def binread(path)
      ::File.binread path
    end

    def write(path, data)
      FileUtils.mkdir_p ::File.dirname(path)
      ::File.write path, data
    end

    def binwrite(path, data)
      FileUtils.mkdir_p ::File.dirname(path)
      ::File.binwrite path, data
    end

    def stat(path)
      ::File.stat(path)
    end

    def size(path)
      ::File.size(path)
    end

    def content_type(path, default = nil)
      ::SS::MimeType.find(path, default)
    end

    def mkdir_p(path)
      FileUtils.mkdir_p path
    end

    def mv(src, dest)
      FileUtils.mv src, dest
    end

    def rm_rf(path)
      FileUtils.rm_rf path
    end

    def glob(path)
      Dir.glob(path)
    end

    def to_io(path, &block)
      ::File.open(path, "rb", &block)
    end

    def cp(src, dest)
      ::FileUtils.cp(src, dest, preserve: true)
    end

    def cmp(src, dest)
      ::FileUtils.cmp(src, dest)
    end

    def upload(dst, src)
      ::IO.copy_stream(src, dst)
    end
  end
end
