namespace :ss do
  task :delete_download_files => :environment do
    return if Fs.mode != :file

    puts "delete download files"
    Dir.glob("#{Rails.root}/private/download/**/*") do |file|
      next if ::File.directory?(file)

      begin
        mtime = ::File.mtime(file)
        if Time.zone.now > mtime.advance(days: 1)
          ::File.unlink(file)
          puts file
        end
      rescue => e
        Rails.logger.debug("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end
end
