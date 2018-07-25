namespace :cms do
  task export_site: :environment do
    ::Tasks::Cms.export_site
  end

  task import_site: :environment do
    ::Tasks::Cms.import_site
  end
end
