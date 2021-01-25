module Fs::File
  extend ActiveSupport::Concern

  module ClassMethods
    def mode
      :file
    end

    def exists?(path)
      ::FileTest.exists? path
    end

    def file?(path)
      ::FileTest.file? path
    end

    def directory?(path)
      ::FileTest.directory? path
    end

    # to stop reading entire file, these methods was removed
    # use download, upload or to_io
    #
    # def read(path)
    #   ::File.read path
    # end
    #
    # def binread(path)
    #   ::File.binread path
    # end
    #
    # def write(path, data)
    #   ::FileUtils.mkdir_p ::File.dirname(path)
    #   ::File.write path, data
    # end
    #
    # def binwrite(path, data)
    #   ::FileUtils.mkdir_p ::File.dirname(path)
    #   ::File.binwrite path, data
    # end

    def stat(path)
      ::File.stat(path)
    end

    def size(path)
      ::File.stat(path).size
    end

    def content_type(path, default = nil)
      ::SS::MimeType.find(path, default)
    end

    def mkdir_p(path)
      ::FileUtils.mkdir_p path
    end

    def mv(src, dest)
      ::FileUtils.mv src, dest
    end

    def rm_rf(path)
      ::FileUtils.rm_rf path
    end

    def glob(path)
      ::Dir.glob(path)
    end

    # returns object which satisfies rack input stream specification
    # see: https://www.rubydoc.info/github/rack/rack/file/SPEC
    def to_io(path)
      ::File.open(path, "rb")
    end

    def download(src, dst)
      ::IO.copy_stream(src, dst)
    end

    def upload(dst, src)
      ::IO.copy_stream(src, dst)
    end

    def cp(src, dest)
      ::FileUtils.cp(src, dest)
    end

    def cmp(src, dest)
      ::FileUtils.cmp(src, dest)
    end
  end
end
