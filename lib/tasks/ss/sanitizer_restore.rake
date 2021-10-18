namespace :ss do
  # input: sanitizer_input/{ID}_{TIMESTAMP}.ext
  # output: sanitizer_output/{ID}_{FILENAME}_{PID}_marked.ext
  task sanitizer_restore: :environment do
    return unless SS.config.ss.sanitizer_output

    ::Fs.glob("#{Rails.root}/#{SS.config.ss.sanitizer_output}/*").sort.each do |path|
      filename = ::File.basename(path)

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
