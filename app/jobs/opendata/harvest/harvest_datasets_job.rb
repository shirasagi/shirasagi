class Opendata::Harvest::HarvestDatasetsJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.warn(message)
    puts message
  end

  def perform(opts = {})
    importer_ids = opts[:importers]
    exporter_ids = opts[:exporters]

    exporters = Opendata::Harvest::Exporter.site(site)
    exporters = exporters.in(id: exporter_ids.map(&:to_i)) if exporter_ids

    importers = Opendata::Harvest::Importer.site(site)
    importers = importers.in(id: importer_ids.map(&:to_i)) if importer_ids

    put_log("importers: " + importers.map { |item| "#{item.name}(#{item.id})" }.join(",") )
    put_log("exporters: " + exporters.map { |item| "#{item.name}(#{item.id})" }.join(",") )
    put_log("")

    importers.each(&:import)
    exporters.each(&:export)
  end
end
