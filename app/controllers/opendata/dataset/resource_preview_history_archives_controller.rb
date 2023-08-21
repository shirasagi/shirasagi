class Opendata::Dataset::ResourcePreviewHistoryArchivesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Opendata::Dataset::ResourceHistoryArchiveFilter

  model Opendata::ResourcePreviewHistory::ArchiveFile

  private

  def set_crumbs
    @crumbs << [t("opendata.histories.history"), opendata_dataset_history_main_path]
    @crumbs << [t("opendata.histories.preview_histories"), opendata_dataset_history_previews_main_path]
    @crumbs << [t("opendata.histories.preview_history_archives"), action: :index]
  end
end
