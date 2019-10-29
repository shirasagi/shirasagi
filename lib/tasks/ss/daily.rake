namespace :ss do
  task daily: :environment do
    Rake.application.invoke_task("ss:delete_download_files")
    Rake.application.invoke_task("ss:delete_access_tokens")
    Rake.application.invoke_task("history:trash:purge")
    Rake.application.invoke_task("gws:trash:purge")
  end
end
