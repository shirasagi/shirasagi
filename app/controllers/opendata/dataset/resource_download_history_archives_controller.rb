class Opendata::Dataset::ResourceDownloadHistoryArchivesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::ResourceDownloadHistory::ArchiveFile

  navi_view "opendata/main/navi"

  before_action :set_search_params
  before_action :set_items

  private

  def set_crumbs
    @crumbs << [t("opendata.histories.history"), opendata_dataset_history_main_path]
    @crumbs << [t("opendata.histories.download_histories"), opendata_dataset_history_downloads_main_path]
    @crumbs << [t("opendata.histories.download_history_archives"), action: :index]
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      s
    end
  end

  def set_items
    @items ||= @model.site(@cur_site).search(@s)
  end

  public

  def index
    @items = @items.page(params[:page]).per(50)
  end

  def show
    render
  end

  def delete
    render
  end

  def destroy
    render_destroy @item.destroy
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      next if item.destroy

      @items << item
    end

    render_destroy_all(entries.size != @items.size)
  end
end
