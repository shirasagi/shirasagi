class Opendata::Dataset::ResourceDownloadHistoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Opendata::Dataset::ResourceHistoryFilter

  model Opendata::ResourceDownloadHistory

  self.csv_filename_base = "dataset_download_history"

  private

  def set_crumbs
    @crumbs << [t("opendata.histories.history"), opendata_dataset_history_main_path]
    @crumbs << [t("opendata.histories.download_histories"), opendata_dataset_history_downloads_main_path]
  end
end
