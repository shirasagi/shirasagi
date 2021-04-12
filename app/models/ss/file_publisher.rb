class SS::FilePublisher
  class Base
    def depublish(file, dirname)
      ::Fs.rm_rf(dirname)
    end
  end

  class ByCopy < Base
    MAX_COMPARE_FILE_SIZE = SS.config.env.max_compare_file_size || 100 * 1_024
    DEFAULT_BUFFER_SIZE = 4 * 1_024

    def publish(file, dirname)
      src = file.path
      return unless ::Fs.exists?(src)

      ::Fs.mkdir_p(dirname)

      # on some conditions, filename doesn't normalize. so it needs to be checked.
      if file.filename.ascii_only?
        publish_one(src, "#{dirname}/#{file.filename}")
      end
      # on some conditions, name aren't url-safe. so it needs to be checked.
      if SS::FilenameUtils.url_safe_japanese?(file.name)
        publish_one(src, "#{dirname}/#{file.name}")
      end
    end

    def publish_one(src, dest)
      return if ::Fs.exists?(dest) && compare_file_head(src, dest)

      ::Fs.rm_rf(dest)
      ::Fs.cp(src, dest)
    end

    private

    def compare_file_head(src, dest, max_size: nil)
      # ::Fs.cmp(src, dest)
      src_io = ::Fs.to_io(src)
      dest_io = ::Fs.to_io(dest)

      compare_stream_head(src_io, dest_io, max_size: max_size)
    ensure
      dest_io.close if dest_io
      src_io.close if src_io
    end

    def compare_stream_head(lhs, rhs, max_size: nil)
      max_size ||= MAX_COMPARE_FILE_SIZE
      lhs_buff = new_buffer(DEFAULT_BUFFER_SIZE)
      rhs_buff = new_buffer(DEFAULT_BUFFER_SIZE)

      nread = 0
      loop do
        return true if nread >= max_size

        lhs.read(DEFAULT_BUFFER_SIZE, lhs_buff)
        rhs.read(DEFAULT_BUFFER_SIZE, rhs_buff)
        nread += lhs_buff.length

        return true if lhs_buff.empty? && rhs_buff.empty?
        break if lhs_buff != rhs_buff
      end

      false
    end

    if RUBY_VERSION > "2.4"
      def new_buffer(buff_size)
        String.new(capacity: buff_size)
      end
    else
      def new_buffer(_buff_size)
        # String.new
        ''
      end
    end
  end

  # BySymLink only supports file system, this doesn't support grid-fs
  class BySymLink < Base
    def publish(file, dirname)
      src = file.path
      return unless ::File.exists?(src)

      ::FileUtils.mkdir_p(dirname) unless ::Dir.exists?(dirname)

      # on some conditions, filename doesn't normalize. so it needs to be checked.
      if file.filename.ascii_only?
        publish_one(src, "#{dirname}/#{file.filename}")
      end
      # on some conditions, name aren't url-safe. so it needs to be checked.
      if SS::FilenameUtils.url_safe_japanese?(file.name)
        publish_one(src, "#{dirname}/#{file.name}")
      end
    end

    def publish_one(src, dest)
      return if ::File.symlink?(dest) && ::File.readlink(dest) == src

      ::FileUtils.rm_rf(dest)
      ::FileUtils.ln_s(src, dest)
    end
  end

  class << self
    delegate :publish, :depublish, to: :singleton

    private

    def singleton
      @singleton ||= begin
        if SS.config.ss.publish_file_with == "ln_s" && SS.config.env.storage == "file"
          BySymLink.new
        else
          ByCopy.new
        end
      end
    end
  end
end
