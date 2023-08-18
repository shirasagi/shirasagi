class Opendata::Harvest::ExportDatasetsJob < Cms::ApplicationJob
  def perform(exporter_id)
    if exporter_id
      Opendata::Harvest::Exporter.find(exporter_id).export
    else
      Opendata::Harvest::Exporter.site(site).each do |exporter|
        exporter.export
      end
    end
  end
end
