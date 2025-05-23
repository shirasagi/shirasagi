namespace :ss do
  # input: #{Rails.root}/sanitizer_input/{PREFIX}_{TYPE}_{ID}_{TIMESTAMP}.ext
  # output: #{Rails.root}/sanitizer_output/{PREFIX}_{TYPE}_{ID}_{FILENAME}_{PID}_{SUFFIX}.ext
  task sanitizer_restore: :environment do
    return unless SS::UploadPolicy.sanitizer_output_path

    allow_suffix = %w(marked marked.MSOfficeWithPassword withPassword withEncrypt sanitized)

    ::Fs.glob("#{SS::UploadPolicy.sanitizer_output_path}/*").sort.each do |path|
      filename = ::File.basename(path)
      basename = ::File.basename(filename, '.*')
      next unless filename.start_with?("#{SS.config.ss.sanitizer_file_prefix}_")

      SS::UploadPolicy.sanitizer_rename_zip(path) if ::File.extname(path) == '.zip'

      if job_model = Uploader::JobFile.sanitizer_restore(path)
        puts "restored: #{filename} -> #{job_model.path}"
        next
      end

      if file = SS::UploadPolicy.sanitizer_restore(path)
        puts "restored: #{filename} -> #{file.path}"
        next
      end

      Fs.rm_rf(path)
      puts "removed: #{filename}"
    end
  end
end
