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
    @crumbs << [t("opendata.histories.download_histories"), { action: :index }]
  end

  def set_search_params
    @s ||= begin
      # now = Time.zone.now
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      # s.start_year ||= now.year
      # s.start_month ||= now.month
      # s.end_year ||= now.year
      # s.end_month ||= now.month
      # s.type ||= "day"
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
    send_enum @items.enum_csv(@cur_site, @cur_node), type: 'text/csv; charset=Shift_JIS',
              filename: "dataset_download_report_#{Time.zone.now.to_i}.csv"
  end
end
