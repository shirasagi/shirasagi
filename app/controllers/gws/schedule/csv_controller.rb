class Gws::Schedule::CsvController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << ['CSV', gws_schedule_csv_path]
  end

  public

  def index
    @item = Gws::Schedule::PlanCsv::Importer.new #get_params

    #@items = Gws::User.site(@cur_site).
    #  active.
    #  search(params[:s]).
    #  order_by_title(@cur_site)
  end

  def export
    @items = Gws::Schedule::Plan.site(@cur_site).
      member(@cur_user).
      search(params[:s])


    #enum = Gws::Schedule::PlanCsv::Exporter.dump_csv(@items, site: @cur_site);exit

    filename = "gws_schedule_plans_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum(
      Gws::Schedule::PlanCsv::Exporter.enum_csv(@items, site: @cur_site),
      type: 'text/csv; charset=Shift_JIS', filename: filename
    )
  end

  def import
    @item = Gws::Schedule::PlanCsv::Importer.new params[:item]
    @item.cur_user = @cur_user
    @item.cur_site = @cur_site

    if @item.invalid?
      render json: { messages: @item.errors.full_messages }.to_json
    elsif params[:import_mode] == "save"
      @item.import
      render json: { messages: [t("gws/schedule.import.saved", count: @item.imported)] }.to_json
    else
      @item.import(confirm: true)
      render json: { items: @item.items }.to_json
    end
  end
end
