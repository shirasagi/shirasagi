class Opendata::Harvest::DestroyDatasetsJob < Cms::ApplicationJob
  def perform(importer_id)
    if importer_id
      Opendata::Harvest::Importer.find(importer_id).destroy_imported_datasets
    else
      Opendata::Harvest::Importer.site(site).each do |importer|
        importer.destroy_imported_datasets
      end
    end
  end
end
