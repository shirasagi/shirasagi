class Opendata::Harvest::ImportDatasetsJob < Cms::ApplicationJob
  def perform(importer_id)
    if importer_id
      Opendata::Harvest::Importer.find(importer_id).import
    else
      Opendata::Harvest::Importer.site(site).each do |importer|
        importer.import
      end
    end
  end
end
