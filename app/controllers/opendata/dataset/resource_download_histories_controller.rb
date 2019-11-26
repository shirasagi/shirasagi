class Opendata::Dataset::ResourceDownloadHistoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::ResourceDownloadHistory
  helper Opendata::ListHelper

  navi_view "opendata/main/navi"
  menu_view nil

  before_action :set_search_params
  before_action :set_items

  private

  def set_crumbs
    @crumbs << [t("opendata.histories.history"), opendata_dataset_history_main_path]
    @crumbs << [t("opendata.histories.download_histories"), opendata_dataset_history_downloads_main_path]
  end

  def set_cur_ymd
    @cur_ymd ||= begin
      ymd = params[:ymd]
      raise "404" if ymd.blank? || !ymd.numeric?

      Time.zone.local(ymd[0..3].to_i, ymd[4..5].to_i, ymd[6..7].to_i)
    end
  end

  def set_search_params
    set_cur_ymd

    @s ||= begin
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      s.ymd ||= @cur_ymd
      s
    end
  end

  def set_items
    @items ||= @model.site(@cur_site).search(@s).order_by(site_id: 1, downloaded: -1)
  end

  public

  def index
    @items = @items.page(params[:page]).per(50)
  end

  def download
    enum = Opendata::ResourceDownloadHistory::HistoryCsv.enum_csv(@cur_site, @items)
    send_enum enum, type: 'text/csv; charset=Shift_JIS',
              filename: "dataset_download_history_#{Time.zone.now.to_i}.csv"
  end
end
