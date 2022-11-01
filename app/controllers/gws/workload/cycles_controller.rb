class Gws::Workload::CyclesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter

  model Gws::Workload::Cycle

  navi_view "gws/workload/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workload_label || I18n.t('modules.gws/workload'), gws_workload_main_path]
    @crumbs << [I18n.t('mongoid.models.gws/workload/cycle'), { action: :index }]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    params[:s] ||= {}
    params[:s][:site] = @cur_site
    params[:s][:year] = @year if @year.present?

    @items = @model.site(@cur_site).
      search(params[:s]).
      allow(:read, @cur_user, site: @cur_site).
      page(params[:page]).per(50)
  end
end
