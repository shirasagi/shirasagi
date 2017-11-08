class Gws::HistoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::History

  # navi_view "gws/main/conf_navi"
  navi_view 'gws/histories/navi'

  before_action :set_year_month

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/history"), action: :index]
  end

  def set_year_month
    if params[:year].blank?
      now = Time.zone.now
      redirect_to gws_monthly_histories_path(year: now.year, month: now.month)
      return
    end

    @s = OpenStruct.new(params[:s])
    @s.year = params[:year]
    @s.month = params[:month]
  end

  public

  def index
    raise '403' unless Gws::History.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      search(@s).
      page(params[:page]).per(50)
  end
end
