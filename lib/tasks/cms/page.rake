namespace :cms do
  task generate_pages: :environment do
    ::Tasks::Cms.generate_pages
  end

  task update_pages: :environment do
    ::Tasks::Cms.update_pages
  end

  task release_pages: :environment do
    ::Tasks::Cms.release_pages
  end

  task remove_pages: :environment do
    ::Tasks::Cms.remove_pages
  end

  task check_links: :environment do
    ::Tasks::Cms.check_links
  end

  task import_files: :environment do
    ::Tasks::Cms.import_files
  end

  task expiration_notices: :environment do
    ::Tasks::Cms.expiration_notices
  end
end
