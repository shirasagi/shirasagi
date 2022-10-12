class Gws::Schedule::HolidaysController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::CalendarFilter
  include Gws::Schedule::CalendarFilter::Transition

  navi_view "gws/schedule/main/navi"
  menu_view "gws/schedule/holidays/menu"

  model Gws::Schedule::Holiday

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/schedule.navi.holiday'), gws_schedule_holidays_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    { start_on: params[:start] || I18n.l(Time.zone.today, format: :picker) }
  end

  def crud_redirect_url
    path = params.dig(:calendar, :path)
    if path.present?
      uri = URI(path)
      uri.query = { calendar: redirection_calendar_params }.to_param
      uri.to_s
    else
      { action: :index }
    end
  end

  def set_item
    super
    raise "404" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    @item.edit_range = params.dig(:item, :edit_range)
    render_destroy @item.destroy
  end

  def copy
    set_item
    @item = @item.new_clone
    render template: "new"
  end

  def events
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s])

    render json: @items.map { |m| m.calendar_format(editable: true) }.to_json
  end

  def download
    csv = @model.unscoped.site(@cur_site).to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "gws_holidays_#{Time.zone.now.to_i}.csv"
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
