class Gws::Schedule::CsvController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  model Gws::Schedule::PlanCsv::Importer

  navi_view "gws/schedule/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('ss.links.import'), gws_schedule_csv_path]
  end

  public

  def index
    @item = @model.new
  end

  def import
    @item = @model.new get_params
    @item.cur_user = @cur_user
    @item.cur_site = @cur_site

    if @item.invalid?
      render json: { messages: @item.errors.full_messages }.to_json
    elsif params[:import_mode] == "save"
      @item.import
      render json: { items: @item.items, messages: [t("gws/schedule.import.count", count: @item.imported)] }.to_json
    else
      @item.import(confirm: true)
      render json: { items: @item.items }.to_json
    end
  end

  def download_template
    filename = "gws_schedule_plans_template.csv"
    response.status = 200
    send_enum(
      Gws::Schedule::PlanCsv::Exporter.enum_template_csv(site: @cur_site, user: @cur_user),
      type: 'text/csv; charset=Shift_JIS', filename: filename
    )
  end
end
