namespace :ss do
  task delete_download_files: :environment do
    SS::DeleteDownloadFilesJob.perform_now
  end
end
