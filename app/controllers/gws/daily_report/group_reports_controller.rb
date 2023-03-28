class Gws::DailyReport::GroupReportsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::DailyReport::Report

  before_action :set_group
  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_search_params
  before_action :set_cur_date
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :soft_delete]

  helper_method :year_month_options, :group_options

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_daily_report_label || t("gws/daily_report.department"), action: :index]
  end

  def set_group
    @group ||= @cur_user.groups.in_group(@cur_site).find(params[:group])
    raise '403' unless @group
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::DailyReport::Form.site(@cur_site)
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.where(year: @cur_site.fiscal_year, daily_report_group_id: @group.id)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_cur_form
    return if params[:form_id].blank? || params[:form_id] == 'default'
    set_forms
    @cur_form ||= @forms.find(params[:form_id])
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new params[:s]
      s.cur_site = @cur_site
      s.cur_user = @cur_user
      s
    end
  end

  def set_cur_date
    raise '404' if params[:ymd].blank? || params[:ymd].length != 8

    year = params[:ymd][0..3]
    month = params[:ymd][4..5]
    date = params[:ymd][6..7]
    @cur_date = Time.zone.parse("#{year}/#{month}/#{date}")
  end

  def set_items
    set_search_params
    @items ||= begin
      items = @model.site(@cur_site).without_deleted.and_date(@cur_date).and_groups([@group]).search(@s)
      items = items.and_user(@cur_user) if @cur_site.fiscal_year(@cur_date) != @cur_site.fiscal_year
      items
    end
  end

  def set_item
    set_items

    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end

    @cur_form ||= @item.form if @item.present?
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    if params[:action] == 'show'
      redirect_to gws_daily_report_group_reports_path
      return
    end
    raise e
  end

  def fix_params
    set_cur_form
    params = { cur_user: @cur_user, cur_site: @cur_site }
    params[:cur_form] = @cur_form if @cur_form
    params
  end

  def year_month_options
    set_active_year_range

    options = []
    date = @active_year_range.last
    while date >= @active_year_range.first
      options << [l(date.to_date, format: :attendance_year_month), "#{date.year}#{format('%02d', date.month)}"]
      date -= 1.month
    end
    options
  end

  def group_options
    @groups.map { |g| [g.section_name, g.id] }
  end

  public

  def index
    @items = @items.page(params[:page]).per(50)
  end

  def show
    render
  end

  def new
    if params[:form_id].blank?
      form_select
      return
    end

    @item = @model.new pre_params.merge(fix_params)
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    render_opts = { template: "new" }
    render_opts[:layout] = false if request.xhr?
    render render_opts
  end

  def form_select
    set_forms
    @forms = @forms.search(params[:s]).page(params[:page]).per(50)
    render template: 'form_select'
  end

  def create
    @item = @model.new get_params
    if @cur_form.present? && params[:custom].present?
      custom = params.require(:custom)
      new_column_values = @cur_form.build_column_values(custom)
      @item.update_column_values(new_column_values)
    end
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    render_create @item.save
  end

  def edit
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock) && !@item.acquire_lock
      redirect_to action: :lock
      return
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if @cur_form.present? && params[:custom].present?
      custom = params.require(:custom)
      new_column_values = @cur_form.build_column_values(custom)
      @item.update_column_values(new_column_values)
    end
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    render_update @item.save
  end

  def delete
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)
    render
  end

  def destroy
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.destroyable?(@cur_user, site: @cur_site)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def print
    @portrait = 'horizontal'
    render layout: 'ss/print'
  end

  def download_all
    if request.get? || request.head?
      return
    end

    if params[:item].present?
      csv_params = params.require(:item).permit(:encoding, :export_target)
    else
      csv_params = {}
    end
    csv_params.merge!(fix_params)

    set_items

    filename = "daily_report_group_csv_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    encoding = csv_params[:encoding]
    send_enum(
      @items.group_csv(site: @cur_site, user: @cur_user, group: @group, options: csv_params),
      type: "text/csv; charset=#{encoding}", filename: filename
    )
  end
end
