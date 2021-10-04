namespace :ss do
  # input: sanitizer_input/{ID}_{TIMESTAMP}.ext
  # output: sanitizer_output/{ID}_{FILENAME}_{PID}_marked.ext
  task sanitizer_restore: :environment do
    return unless SS.config.ss.sanitizer_output

    ::Fs.glob("#{Rails.root}/#{SS.config.ss.sanitizer_output}/*").sort.each do |path|
      filename = ::File.basename(path)

      if Uploader::JobFile.sanitizer_restore(path)
        puts "restored: #{filename}"
        next
      end

      if file = SS::UploadPolicy.sanitizer_restore(path)
        puts "restored: #{filename}"

        if task = SS::SanitizerJobFile.restore_wait_job(file)
          puts "task: #{task.id} #{task[:class_name]}"
        end
        next
      end

      Fs.rm_rf(path)
      puts "removed: #{filename}"
    end
  end
end
