namespace :ss do
  task :daily => :environment do
    Rake.application.invoke_task("ss:delete_download_files")
  end
end
