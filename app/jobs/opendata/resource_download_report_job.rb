class Opendata::ResourceDownloadReportJob < Cms::ApplicationJob
  include Opendata::ResourceReportBase

  self.target_models = [
    Opendata::ResourceDownloadHistory,
    Opendata::ResourceDatasetDownloadHistory,
    Opendata::ResourceBulkDownloadHistory
  ].freeze
  self.issued_at_field = :downloaded
  self.report_model = Opendata::ResourceDownloadReport
end
