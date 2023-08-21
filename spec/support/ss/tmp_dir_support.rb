module SS
  module TmpDir
    module_function

    def tmpdir
      @tmpdir ||= ::Dir.mktmpdir
    end

    def tmpdir=(value)
      @tmpdir = value
    end

    def cleanup_tmpdir
      tmpdir = @tmpdir
      @tmpdir = nil
      return if tmpdir.blank?

      ::FileUtils.rm_rf(tmpdir)
    end

    def tmpfile(options = {}, &block)
      tmpfile = "#{::SS::TmpDir.tmpdir}/#{unique_id}"
      tmpfile = "#{tmpfile}#{options[:extname]}" if options[:extname]
      mode = options[:binary] ? "wb" : "w"
      mode = "#{mode}:#{options[:encoding]}" if options[:encoding]

      ::File.open(tmpfile, mode, &block)
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
      attr[:content_type] = options.delete(:content_type) || ::Fs.content_type(basename)
      file_model.create_empty!(attr.update(options)) do |ss_file|
        write_contents_to(ss_file, contents, binary)
      end
    end

    def extract_basename_from_contents(contents)
      if contents.respond_to?(:path)
        ::File.basename(contents.path)
      elsif contents.present? && (::File.exist?(contents) rescue false)
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
      elsif contents.present? && (::File.exist?(contents) rescue false)
        ::FileUtils.copy_file(contents, ss_file.path)
      elsif binary
        ::File.binwrite(ss_file.path, contents)
      else
        ::File.write(ss_file.path, contents)
      end
    end

    module Support
      def self.extended(obj)
        obj.after(:example) do
          ::SS::TmpDir.cleanup_tmpdir
        end

        obj.class_eval do
          delegate :tmpdir, :cleanup_tmpdir, :tmpfile, :tmp_ss_file, to: ::SS::TmpDir
        end
      end
    end
  end
end

RSpec.configuration.extend(SS::TmpDir::Support)
