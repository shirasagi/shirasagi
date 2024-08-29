namespace :opendata do
  namespace :metadata do
    task import_datasets: :environment do
      ::Tasks::Cms.each_sites do |site|
        ::Opendata::Metadata::ImportDatasetsJob.bind(site_id: site.id).perform_now(
          importer_id: ENV['importer'],
          notice: ENV['notice']
        )
      end
    end

    task destroy_datasets: :environment do
      ::Tasks::Cms.each_sites do |site|
        ::Opendata::Metadata::DestroyDatasetsJob.bind(site_id: site.id).perform_now(ENV['importer'])
      end
    end
  end
end
