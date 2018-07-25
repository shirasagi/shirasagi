namespace :cms do
  task set_subdir_url: :environment do
    ::Tasks::Cms.set_subdir_url
  end
end
