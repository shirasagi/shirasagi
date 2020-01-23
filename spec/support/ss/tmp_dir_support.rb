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

    def tmp_ss_file(*args)
      options = args.extract_options!.dup
      file_model = args.first || constantize_file_model(options[:model]) || SS::File
      contents = options.delete(:contents)
      binary = options.delete(:binary)

      site = options.delete(:site)
      user = options.delete(:user)
      node = options.delete(:node)

      basename = options.delete(:basename) || extract_basename_from_contents(contents) || "spec"
      attr = { model: options.delete(:model) || "ss/temp_file", name: basename, filename: basename }
      attr[:site_id] = site.id if site
      if user
        attr[:cur_user] = user
        attr[:user_id] = user.id
      end
      attr[:node_id] = node.id if node
      attr[:content_type] = options.delete(:content_type) || ::Fs.content_type(basename, "application/octet-stream")
      file_model.create_empty!(attr.update(options)) do |ss_file|
        write_contents_to(ss_file, contents, binary)
      end
    end

    def extract_basename_from_contents(contents)
      if contents.respond_to?(:path)
        ::File.basename(contents.path)
      elsif contents.present? && (::File.exists?(contents) rescue false)
        ::File.basename(contents)
      end
    end

    def constantize_file_model(model)
      return if model.blank?

      klass = model.classify.constantize
      return unless klass.ancestors.include?(SS::Model::File)

      klass
    rescue LoadError
      nil
    end

    def write_contents_to(ss_file, contents, binary)
      if contents.respond_to?(:path)
        ::FileUtils.copy_file(contents.path, ss_file.path)
      elsif contents.present? && (::File.exists?(contents) rescue false)
        ::FileUtils.copy_file(contents, ss_file.path)
      elsif binary
        ::File.binwrite(ss_file.path, contents)
      else
        ::File.write(ss_file.path, contents)
      end
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

          delegate :created_tmpdir, :tmpfile, :tmp_ss_file, to: ::SS::TmpDir
        end
      end
    end
  end
end

RSpec.configuration.extend(SS::TmpDir::Support)
