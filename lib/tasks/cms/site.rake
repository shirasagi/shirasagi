namespace :cms do
  task export_site: :environment do
    ::Tasks::Cms.export_site
  end

  task import_site: :environment do
    ::Tasks::Cms.import_site
  end

  task reload_site_usage: :environment do
    ::Tasks::Cms.reload_site_usage
  end
end
