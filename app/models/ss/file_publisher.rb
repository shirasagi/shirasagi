class SS::FilePublisher
  class Base
    def depublish(file, dirname)
      ::Fs.rm_rf(dirname)
    end
  end

  class ByCopy < Base
    def publish(file, dirname)
      src = file.path
      return unless ::Fs.exist?(src)

      ::Fs.mkdir_p(dirname)

      # on some conditions, filename doesn't normalize. so it needs to be checked.
      if file.filename.ascii_only?
        publish_one(src, "#{dirname}/#{file.filename}")
      end
      # on some conditions, name aren't url-safe. so it needs to be checked.
      if SS::FilenameUtils.url_safe_japanese?(file.name)
        publish_one(src, "#{dirname}/#{file.name}")
      end
      file.variants.each do |variant|
        variant_src = variant.path
        next unless ::Fs.exist?(variant_src)

        if variant.filename.ascii_only?
          publish_one(variant_src, "#{dirname}/#{variant.filename}")
        end
        if SS::FilenameUtils.url_safe_japanese?(variant.name)
          publish_one(variant_src, "#{dirname}/#{variant.name}")
        end
      end
    end

    def publish_one(src, dest)
      return if ::Fs.exist?(dest) && ::Fs.compare_file_head(src, dest)

      ::Fs.rm_rf(dest)
      ::Fs.cp(src, dest)
    end
  end

  # BySymLink only supports file system, this doesn't support grid-fs
  class BySymLink < Base
    def publish(file, dirname)
      src = file.path
      return unless ::File.exist?(src)

      ::FileUtils.mkdir_p(dirname) unless ::Dir.exist?(dirname)

      # on some conditions, filename doesn't normalize. so it needs to be checked.
      if file.filename.ascii_only?
        publish_one(src, "#{dirname}/#{file.filename}")
      end
      # on some conditions, name aren't url-safe. so it needs to be checked.
      if SS::FilenameUtils.url_safe_japanese?(file.name)
        publish_one(src, "#{dirname}/#{file.name}")
      end
      file.variants.each do |variant|
        variant_src = variant.path
        next unless ::Fs.exist?(variant_src)

        if variant.filename.ascii_only?
          publish_one(variant_src, "#{dirname}/#{variant.filename}")
        end
        if SS::FilenameUtils.url_safe_japanese?(variant.name)
          publish_one(variant_src, "#{dirname}/#{variant.name}")
        end
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
