class Gws::Facility::ItemsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility::Item

  navi_view "gws/schedule/main/navi"
  menu_view "gws/facility/main/menu"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/facility.navi.item'), gws_facility_items_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      state(params.dig(:s, :state)).
      search(params[:s]).
      allow(:read, @cur_user, site: @cur_site).
      page(params[:page]).per(50)
  end

  def download_all
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    if request.get? || request.head?
      @model = SS::DownloadParam
      @item = SS::DownloadParam.new
      render
      return
    end

    @item = SS::DownloadParam.new params.require(:item).permit(:encoding)
    if @item.invalid?
      render
      return
    end

    csv = @model.unscoped.site(@cur_site).to_csv
    case @item.encoding
    when "Shift_JIS"
      csv = csv.encode("SJIS", invalid: :replace, undef: :replace)
    when "UTF-8"
      csv = SS::Csv::UTF8_BOM + csv
    end

    send_data csv, filename: "gws_facility_items_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get? || request.head?

    @item = @model.new get_params
    @item.cur_site = @cur_site
    @item.cur_user = @cur_user
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { template: "import" }
  end
end
