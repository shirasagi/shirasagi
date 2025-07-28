class Opendata::Harvest::ExportJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.warn(message)
    puts message
  end

  def perform(opts = {})
    exporter_ids = opts[:exporters]

    exporters = Opendata::Harvest::Exporter.site(site)
    exporters = exporters.in(id: exporter_ids.map(&:to_i)) if exporter_ids

    put_log("exporters: " + exporters.map { |item| "#{item.name}(#{item.id})" }.join(",") )
    put_log("")

    exporters.each(&:export)
  end
end
