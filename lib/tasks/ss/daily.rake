namespace :ss do
  task daily: :environment do
    Rake.application.invoke_task("ss:delete_download_files")

    Cms::Site.each do |site|
      ENV['site'] = site.host
      Rake.application.invoke_task("cms:trash:purge")
      ENV['site'] = nil
    end
  end
end
