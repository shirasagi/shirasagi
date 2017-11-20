class Gws::HistoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::History

  navi_view 'gws/histories/navi'

  before_action :set_ymd

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/history"), action: :index]
  end

  def set_ymd
    if params[:ymd].blank?
      redirect_to gws_daily_histories_path(ymd: Time.zone.now.strftime('%Y%m%d'))
      return
    end

    @s = OpenStruct.new(params[:s])
    @s.ymd = params[:ymd]
  end

  def set_items
    @items = @model.site(@cur_site).search(@s)
  end

  public

  def index
    raise '403' unless Gws::History.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    @items = @items.page(params[:page]).per(50)
  end

  def download
    raise '403' unless Gws::History.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    return if request.get?

    filename = 'gws_histories'
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum Gws::HistoryCsv.enum_csv(@cur_site, @items), type: 'text/csv; charset=Shift_JIS', filename: filename
  end
end
