# 一時ファイルの削除（エクスポート）
class SS::DeleteDownloadFilesJob < SS::ApplicationJob
  def perform
    return if Fs.mode != :file

    puts "delete download files"
    Dir.glob("#{Rails.root}/private/download/**/*") do |file|
      next if ::File.directory?(file)

      Rails.logger.tagged(file) do
        mtime = ::File.mtime(file)
        if Time.zone.now > mtime.advance(days: 1)
          ::File.unlink(file)
          puts file

          dir = File.dirname(file)
          2.times do
            break unless Dir.exist?(dir)
            break unless Dir.empty?(dir)
            FileUtils.remove_dir(dir)
            dir = File.dirname(dir)
          end
        end
      rescue => e
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end
end
