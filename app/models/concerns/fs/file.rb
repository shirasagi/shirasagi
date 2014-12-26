require "mime/types"
module Fs::File
  extend ActiveSupport::Concern

  module ClassMethods
    def mode
      :file
    end

    def exists?(path)
      FileTest.exists? path
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
      ::File.stat(path).size
    end

    def content_type(path)
      ::MIME::Types.type_for(path).first.content_type rescue nil
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
  end
end
