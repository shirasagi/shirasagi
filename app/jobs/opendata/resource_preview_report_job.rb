class Opendata::ResourcePreviewReportJob < Cms::ApplicationJob
  include Opendata::ResourceReportBase

  self.target_models = [ Opendata::ResourcePreviewHistory ].freeze
  self.issued_at_field = :previewed
  self.report_model = Opendata::ResourcePreviewReport
end
