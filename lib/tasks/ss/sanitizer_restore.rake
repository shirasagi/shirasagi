namespace :ss do
  # input: sanitizer_input/{ID}_{TIMESTAMP}.ext
  # output: sanitizer_output/{ID}_{FILENAME}_{PID}_marked.ext
  task sanitizer_restore: :environment do
    return unless SS.config.ss.sanitizer_output

    ::Fs.glob("#{Rails.root}/#{SS.config.ss.sanitizer_output}/*").sort.each do |path|
      filename = ::File.basename(path)
      next unless filename =~ /\A\d+_\d+.*_\d+_marked/

      id = filename.sub(/^(\d+).*/, '\\1').to_i
      file = SS::File.find(id).becomes_with_model rescue nil

      if file.nil?
        Fs.rm_rf(path)
        puts "removed: #{filename}"
        next
      end

      if file.sanitizer_restore_file(path)
        puts "restored: #{filename}"
      else
        Rails.logger.error("sanitier_restore_file: #{file.class}##{id}: #{file.errors.full_messages.join(' ')}")
      end
    end
  end
end
