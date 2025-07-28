class Opendata::Metadata::DestroyDatasetsJob < Cms::ApplicationJob
  def perform(importer_id)
    if importer_id
      Opendata::Metadata::Importer.find(importer_id).destroy_imported_datasets
    else
      Opendata::Metadata::Importer.site(site).where(state: 'enabled').each do |importer|
        importer.destroy_imported_datasets
      end
    end
  end
end
