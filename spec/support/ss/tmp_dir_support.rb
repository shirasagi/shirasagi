module SS
  module TmpDirSupport
    def self.extended(obj)
      obj.before(:example) do
        obj.metadata[:tmpdir] = ::Dir.mktmpdir
      end

      obj.after(:example) do
        tmpdir = obj.metadata[:tmpdir]
        obj.metadata[:tmpdir] = nil
        ::FileUtils.rm_rf(tmpdir) if tmpdir
      end

      obj.class_eval do
        define_method(:tmpdir) do
          obj.metadata[:tmpdir]
        end

        def tmpfile(options = {}, &block)
          tmpfile = "#{tmpdir}/#{unique_id}"
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
          else
            source_file = tmpfile(binary: options.delete(:binary)) { |file| file.write contents }
          end

          ss_file = SS::File.new(model: options.delete(:model) || "ss/temp_file")
          ss_file.user_id = options[:user].id if options[:user]
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
      end
    end
  end
end

RSpec.configuration.extend(SS::TmpDirSupport, tmpdir: true)
