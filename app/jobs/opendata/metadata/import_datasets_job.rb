class Opendata::Metadata::ImportDatasetsJob < Cms::ApplicationJob
  def perform(opts = {})
    if opts[:importer_id].present?
      Opendata::Metadata::Importer.find(opts[:importer_id]).import(notice: opts[:notice])
    else
      Opendata::Metadata::Importer.site(site).where(state: 'enabled').each do |importer|
        importer.import(notice: opts[:notice])
      end
    end
  end
end
