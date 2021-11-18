module Fs::GridFs
  extend ActiveSupport::Concern

  class GridFsError < StandardError; end
  class FileNotFoundError < GridFsError; end

  class Stat
    attr_reader :size, :atime, :mtime, :ctime

    def initialize(obj)
      @size  = obj[:length]
      @atime = obj[:updated] || obj[:uploadDate]
      @mtime = @atime
      @ctime = @ctime
    end
  end

  module ClassMethods
    def mode
      :grid_fs
    end

    def path_filter(path)
      patt = ::Regexp.escape(Rails.root.to_s)
      path.sub(/^#{patt}/, "").sub(/^\//, "")
    end

    def get(path)
      path = path_filter(path)
      Mongoid::GridFs.find(filename: path)
    end

    def exist?(path)
      get(path) != nil
    end

    def file?(path)
      exist?(path)
    end

    def directory?(path)
      return false if file?(path)

      Mongoid::GridFs.find(filename: /#{::Regexp.escape(path_filter(path))}/) != nil
    end

    def read(path)
      binread(path)
    end

    def binread(path)
      obj = get(path)
      raise FileNotFoundError if obj.nil?

      obj.data
    end

    def write(path, data)
      binwrite(path, data)
    end

    def binwrite(path, data)
      file = Fs::UploadedFile.new("grid_fs")
      file.binmode
      file.write(data)
      # file.content_type = content_type(path)

      if fs = get(path)
        fs.delete
      end
      fs = Mongoid::GridFs.put file, filename: path_filter(path)
      fs.length
    end

    def stat(path)
      obj = get(path)
      raise FileNotFoundError if obj.nil?

      Stat.new obj
    end

    def size(path)
      stat(path).size
    end

    def content_type(path, default = nil)
      ::SS::MimeType.find(path, default)
    end

    def mkdir_p(path)
      true
    end

    def mv(src, dest)
      src = path_filter(src)
      dest = path_filter(dest)

      count = 0
      Mongoid::GridFs.file_model.where(filename: /^#{::Regexp.escape(src)}(\/.*|$)/).each do |fs|
        count += 1
        fs.filename = fs.filename.sub(src, dest)
        fs.save
      end
      raise FileNotFoundError if count == 0

      0
    end

    def rm_rf(path)
      path0 = path_filter(path)
      path0 = ::Regexp.escape(path0)
      Mongoid::GridFs.file_model.where(filename: /^#{path0}(\/.*|$)/).destroy
      [ path ]
    end

    def glob(path)
      path = path_filter(path)
      path = ::Regexp.escape(path)
      path = path.gsub('\\*\\*/', "([^/]*\/)*")
      path = path.gsub('\\*', ".*")
      Mongoid::GridFs.file_model.where(filename: /^#{path}$/).map { |fs| fs.filename }
    end

    def to_io(path, &block)
      raise NotImplementedError
    end

    def cp(src, dest)
      binwrite(dest, binread(src))
    end

    def upload(dst, src)
      fs = get(dst)
      fs.delete if fs

      if src.respond_to?(:read)
        fs = Mongoid::GridFs.put(src, filename: path_filter(dst))
      else
        fs = ::File.open(src, "rb") do |io|
          Mongoid::GridFs.put(io, filename: path_filter(dst))
        end
      end

      fs.length
    end
  end
end
