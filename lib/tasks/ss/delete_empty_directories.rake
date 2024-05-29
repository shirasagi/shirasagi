namespace :ss do
  task delete_empty_directories: :environment do
    SS::DeleteEmptyDirectoriesJob.perform_now
  end
end
