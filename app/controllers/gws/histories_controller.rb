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

  public

  def index
    raise '403' unless Gws::History.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      search(@s).
      page(params[:page]).per(50)
  end
end
