class Opendata::Dataset::ResourceDownloadHistoryArchivesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Opendata::Dataset::ResourceHistoryArchiveFilter

  model Opendata::ResourceDownloadHistory::ArchiveFile

  private

  def set_crumbs
    @crumbs << [t("opendata.histories.history"), opendata_dataset_history_main_path]
    @crumbs << [t("opendata.histories.download_histories"), opendata_dataset_history_downloads_main_path]
    @crumbs << [t("opendata.histories.download_history_archives"), action: :index]
  end
end
