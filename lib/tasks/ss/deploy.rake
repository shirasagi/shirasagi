namespace :ss do
  task deploy: :environment do
    assets_path = "#{Rails.public_path}#{Rails.application.config.assets.prefix}"

    Dir.glob("#{assets_path}/**/*.*") do |file|
      if File.basename(file) =~ /^_/
        File.unlink file
      elsif file =~ /-[0-9a-f]{32,}\./
        File.unlink file
      end
    end

    Dir.glob("#{assets_path}/.sprockets-manifest*") do |file|
      File.unlink file
    end
  end
end
