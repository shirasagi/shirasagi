require "mime/types"
module Fs::GridFs
  extend ActiveSupport::Concern

  class Stat
    attr_reader :size, :atime, :mtime, :ctime

    def initialize(fs)
      @size  = fs[:length]
      @atime = fs[:updated] || fs[:uploadDate]
      @mtime = @atime
      @ctime = @ctime
    end
  end

  module ClassMethods
    def mode
      :grid_fs
    end

    def path_filter(path)
      patt = Regexp.escape(Rails.root.to_s)
      path.sub(/^#{patt}/, "").sub(/^\//, "")
    end

    def get(path)
      path = path_filter(path)
      Mongoid::GridFs.find(filename: path)
    end

    def exists?(path)
      get(path) != nil
    end

    def file?(path)
      exists?(path)
    end

    def directory?(path)
      !file?(path)
    end

    def read(path)
      get(path).data
    end

    def binread(path)
      read(path)
    end

    def write(path, data)
      file = Fs::UploadedFile.new("grid_fs")
      file.binmode
      file.write(data)
      #file.content_type = content_type(path)

      if fs = get(path)
        fs.delete
      end
      fs = Mongoid::GridFs.put file, filename: path_filter(path)
    end

    def binwrite(path, data)
      write(path, data)
    end

    def stat(path)
      Stat.new get(path)
    end

    def size(path)
      stat(path).size
    end

    def content_type(path)
      ::MIME::Types.type_for(path).first.content_type rescue nil
    end

    def mkdir_p(path)
      true
    end

    def mv(src, dest)
      dest = path_filter(dest)
      dest = Regexp.escape(dest)

      Mongoid::GridFs.file_model.where(filename: /^#{src}(\/.*|$)/).each do |fs|
        fs.filename = fs.filename.sub(src, dest)
        fs.save
      end
    end

    def rm_rf(path)
      path = path_filter(path)
      path = Regexp.escape(path)
      Mongoid::GridFs.file_model.where(filename: /^#{path}(\/.*|$)/).destroy
    end

    def glob(path)
      path = path_filter(path)
      path = Regexp.escape(path)
      path = path.gsub('\\*\\*/', "([^/]*\/)*")
      path = path.gsub('\\*', ".*")
      Mongoid::GridFs.file_model.where(filename: /^#{path}$/).map { |fs| fs.filename }
    end
  end
end
