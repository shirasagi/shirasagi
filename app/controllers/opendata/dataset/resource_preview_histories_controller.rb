class Opendata::Dataset::ResourcePreviewHistoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Opendata::Dataset::ResourceHistoryFilter

  model Opendata::ResourcePreviewHistory

  self.csv_filename_base = "dataset_preview_history"

  private

  def set_crumbs
    @crumbs << [t("opendata.histories.history"), opendata_dataset_history_main_path]
    @crumbs << [t("opendata.histories.preview_histories"), opendata_dataset_history_previews_main_path]
  end
end
