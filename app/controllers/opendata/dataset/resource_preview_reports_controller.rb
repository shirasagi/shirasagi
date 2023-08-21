class Opendata::Dataset::ResourcePreviewReportsController < ApplicationController
  include Cms::BaseFilter
  include Opendata::Dataset::ResourceReportFilter

  model Opendata::ResourcePreviewReport
  self.csv_filename_base = "dataset_preview_report"

  private

  def set_crumbs
    @crumbs << [t("opendata.reports.report"), opendata_dataset_report_main_path]
    @crumbs << [t("opendata.reports.preview_reports"), { action: :index }]
  end
end
