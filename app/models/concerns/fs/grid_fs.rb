require "stringio"

module Fs::GridFs
  extend ActiveSupport::Concern

  class GridFsError < StandardError; end
  class FileNotFoundError < GridFsError; end

  class Stat
    attr_reader :size, :atime, :mtime, :ctime

    def initialize(grid_file)
      @size  = grid_file[:length]
      @atime = grid_file[:updated] || grid_file[:uploadDate]
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

    def exists?(path)
      get(path) != nil
    end

    def file?(path)
      exists?(path)
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
      io = data ? StringIO.new(data) : StringIO.new
      upload(path, io)
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

    class IoLike
      def initialize(file)
        @file = file
        rewind
      end

      def gets
        output_buffer = ''
        finished = false
        until finished
          break unless next_chunk_if_necessary

          @chunk.each_char do |ch|
            output_buffer << ch
            if ch == "\n"
              finished = true
              break
            end
          end
        end

        output_buffer
      end

      def read(*args)
        length, output_buffer = *args
        output_buffer ||= ''

        output_length = 0
        loop do
          required = nil
          if length.present?
            required = length - output_length
            break if required <= 0
          end

          break unless next_chunk_if_necessary

          remains = @chunk.length - @chunk.pos
          if required.present? && required < remains
            output_buffer << @chunk.read(required)
            output_length += required
            break
          end

          output_buffer << @chunk.read
          output_length += remains
        end

        return nil if length.to_i != 0 && output_length == 0

        output_buffer
      end

      def each
        line = gets
        until line.nil?
          yield line
          line = gets
        end
      end

      def rewind
        @enum = Enumerator.new do |y|
          @file.each { |chunk| y << chunk }
        end
        0
      end

      def close
        @chunk = nil
        rewind
        nil
      end

      private

      def next_chunk
        chunk = @enum.next
        @chunk = StringIO.new(chunk)
        true
      rescue StopIteration => _e
        @chunk = nil
        false
      end

      def next_chunk_if_necessary
        return next_chunk if @chunk.nil?

        remains = @chunk.length - @chunk.pos
        return next_chunk if remains <= 0

        true
      end
    end

    # returns object which satisfies rack input stream specification
    # see: https://www.rubydoc.info/github/rack/rack/file/SPEC
    def to_io(path)
      obj = get(path)
      raise FileNotFoundError if obj.nil?

      IoLike.new(obj)
    end

    def download(src, dst)
      ::IO.copy_stream(to_io(src), dst)
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

    def cp(src, dest)
      binwrite(dest, binread(src))
    end
  end
end
