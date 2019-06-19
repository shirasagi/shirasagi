class Opendata::ReportDatasetJob < Cms::ApplicationJob
  def perform(importer_id)
    importer = Opendata::DatasetImport::Importer.find(importer_id)
    importer.report
  end
end
