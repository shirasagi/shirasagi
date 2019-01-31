class Opendata::Harvest::HarvestDatasetsJob < Cms::ApplicationJob
  def perform(opts = {})
    importer_id = opts[:importer_id]
    exporter_id = opts[:exporter_id]

    if importer_id
      Opendata::Harvest::Importer.find(importer_id).import
    elsif exporter_id
      Opendata::Harvest::Exporter.find(exporter_id).export
    else

      # Import Datasets
      Opendata::Harvest::Importer.site(site).each do |importer|
        importer.import
      end

      # Export Datasets into CKAN
      Opendata::Harvest::Exporter.site(site).each do |exporter|
        exporter.export
      end
    end
  end
end
