module SS
  module TmpDir
    module_function

    def created_tmpdir
      @created_tmpdir
    end

    def created_tmpdir=(value)
      @created_tmpdir = value
    end

    def before_example
      ::SS::TmpDir.created_tmpdir ||= ::Dir.mktmpdir
    end

    def after_example
      tmpdir = ::SS::TmpDir.created_tmpdir
      ::SS::TmpDir.created_tmpdir = nil
      ::FileUtils.rm_rf(tmpdir) if tmpdir
    end

    def tmpfile(options = {}, &block)
      tmpfile = "#{::SS::TmpDir.created_tmpdir}/#{unique_id}"
      tmpfile = "#{tmpfile}#{options[:extname]}" if options[:extname]
      mode = options[:binary] ? "wb" : "w"
      mode = "#{mode}:#{options[:encoding]}" if options[:encoding]

      ::File.open(tmpfile, mode) { |file| yield file }
      tmpfile
    end

    def tmp_ss_file(options = {})
      options = options.dup
      contents = options[:contents]

      if contents.respond_to?(:path)
        source_file = contents.path
      elsif contents.present? && (::File.exists?(contents) rescue false)
        source_file = contents
      else
        source_file = tmpfile(binary: options.delete(:binary)) { |file| file.write contents }
      end

      ss_file = SS::File.new(model: options.delete(:model) || "ss/temp_file")
      ss_file.site_id = options[:site].id if options[:site]
      ss_file.user_id = options[:user].id if options[:user]
      options.delete(:site)
      options.delete(:user)

      basename = options.delete(:basename) || "spec"
      content_type = options.delete(:content_type) || "application/octet-stream"
      Fs::UploadedFile.create_from_file(source_file, basename: basename, content_type: content_type) do |f|
        ss_file.in_file = f
        ss_file.save!
        ss_file.in_file = nil
      end
      ss_file.reload
      ss_file
    end

    def tmp_ss_link_file(options = {})
      options = options.dup
      contents = options[:contents]

      if contents.respond_to?(:path)
        source_file = contents.path
      elsif contents.present? && (::File.exists?(contents) rescue false)
        source_file = contents
      else
        source_file = tmpfile(binary: options.delete(:binary)) { |file| file.write contents }
      end

      ss_file = SS::LinkFile.new(model: options.delete(:model) || "ss/temp_file")
      ss_file.site_id = options[:site].id if options[:site]
      ss_file.user_id = options[:user].id if options[:user]
      options.delete(:site)
      options.delete(:user)

      basename = options.delete(:basename) || "spec"
      content_type = options.delete(:content_type) || "application/octet-stream"
      Fs::UploadedFile.create_from_file(source_file, basename: basename, content_type: content_type) do |f|
        ss_file.in_file = f
        ss_file.save!
        ss_file.in_file = nil
      end
      ss_file.reload
      ss_file
    end

    def tmp_file(options = {})
      options = options.dup
      contents = options[:contents]

      if contents.respond_to?(:path)
        source_file = contents.path
      elsif contents.present? && (::File.exists?(contents) rescue false)
        source_file = contents
      else
        source_file = tmpfile(binary: options.delete(:binary)) { |file| file.write contents }
      end

      ss_file = SS::TempFile.new(model: options.delete(:model) || "ss/temp_file")
      ss_file.site_id = options[:site].id if options[:site]
      ss_file.user_id = options[:user].id if options[:user]
      options.delete(:site)
      options.delete(:user)

      basename = options.delete(:basename) || "spec"
      content_type = options.delete(:content_type) || "application/octet-stream"
      Fs::UploadedFile.create_from_file(source_file, basename: basename, content_type: content_type) do |f|
        ss_file.in_file = f
        ss_file.save!
        ss_file.in_file = nil
      end
      ss_file.reload
      ss_file
    end

    module Support
      def self.extended(obj)
        obj.before(:example) do
          ::SS::TmpDir.before_example
        end

        obj.after(:example) do
          ::SS::TmpDir.after_example
        end

        obj.class_eval do
          define_method(:tmpdir) do
            ::SS::TmpDir.created_tmpdir
          end

          delegate :created_tmpdir, :tmpfile, :tmp_ss_file, :tmp_ss_link_file, :tmpfile, to: ::SS::TmpDir
        end
      end
    end
  end
end

RSpec.configuration.extend(SS::TmpDir::Support, tmpdir: true)
