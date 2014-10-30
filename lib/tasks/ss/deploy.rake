namespace :ss do
  task :deploy => :environment  do
    assets_path = "#{Rails.public_path}#{Rails.application.config.assets.prefix}"

    Dir.glob("#{assets_path}/**/*") do |file|
      if file =~ /-[0-9a-f]{32}\./
        File.unlink(file)

        if File.basename(file) =~ /^_/
          partial = file.gsub(/-[0-9a-f]{32}/, "")
          File.unlink(partial) if File.exist?(partial)
        end
      end
    end
  end
end
