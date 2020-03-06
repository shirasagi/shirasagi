class Opendata::Dataset::AccessReportsController < ApplicationController
  include Cms::BaseFilter
  include Opendata::Dataset::ResourceReportFilter

  model Opendata::DatasetAccessReport
  self.csv_filename_base = "dataset_download_report"

  private

  def set_crumbs
    @crumbs << [t("opendata.reports.report"), opendata_dataset_report_main_path]
    @crumbs << [t("opendata.reports.access_reports"), { action: :index }]
  end
end
