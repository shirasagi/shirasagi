class Opendata::Harvest::ImportJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.warn(message)
    puts message
  end

  def perform(opts = {})
    importer_ids = opts[:importers]

    importers = Opendata::Harvest::Importer.site(site)
    importers = importers.in(id: importer_ids.map(&:to_i)) if importer_ids

    put_log("importers: " + importers.map { |item| "#{item.name}(#{item.id})" }.join(",") )
    put_log("")

    importers.each(&:import)
  end
end
