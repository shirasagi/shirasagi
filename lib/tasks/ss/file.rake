namespace :ss do
  task :export_files_for_update => :environment do
    SS::File.all.each do |file|
      puts file.path
      next unless file[:file_id]

      begin
        dir = File.dirname(file.path)
        FileUtils.mkdir_p(dir) unless File.exists?(dir)

        fs = Mongoid::GridFs.get file[:file_id]
        File.binwrite file.path, fs.data
      rescue StandardError => e
        puts "#{e}"
      end
    end
  end
end
