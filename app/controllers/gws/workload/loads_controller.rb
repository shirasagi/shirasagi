class Gws::Workload::LoadsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Workload::YearFilter

  model Gws::Workload::Load

  navi_view "gws/workload/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workload_label || I18n.t('modules.gws/workload'), gws_workload_main_path]
    @crumbs << [I18n.t('mongoid.models.gws/workload/load'), { action: :index }]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    { year: @year }
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

  def download_all
    if request.get? || request.head?
      render
      return
    end

    safe_params = params.require(:item).permit(:encoding)
    encoding = safe_params[:encoding]

    @item = Gws::Workload::Importer::Load.new(@cur_site, @year, @cur_user)
    enumerable = @item.enum_csv(encoding: encoding)
    filename = "gws_workload_loads_#{Time.zone.now.to_i}.csv"
    send_enum(enumerable, type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def import
    return if request.get? || request.head?

    @item = Gws::Workload::Importer::Load.new(@cur_site, @year, @cur_user)
    file = params[:item].try(:[], :in_file)

    result = @item.import(file)
    render_create result, location: { action: :index }, render: { template: "import" }
  end
end
