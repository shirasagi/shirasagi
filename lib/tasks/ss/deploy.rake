namespace :ss do
  task :deploy => :environment  do
    assets_path = "#{Rails.public_path}#{Rails.application.config.assets.prefix}"

    Dir.glob("#{assets_path}/**/*") do |file|
      File.unlink(file) if file =~ /-[0-9a-f]{32}\./
    end
  end
end
