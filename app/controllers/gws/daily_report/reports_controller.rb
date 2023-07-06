class Gws::DailyReport::ReportsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::DailyReport::ReportFilter

  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_cur_month
  before_action :set_groups
  before_action :set_users
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :soft_delete]

  helper_method :group_options

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [t('modules.gws/daily_report'), gws_daily_report_main_path]
    @crumbs << [@cur_site.menu_daily_report_label || t("gws/daily_report.daily_report_list"), action: :index]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::DailyReport::Form.site(@cur_site)
      if params[:state] != 'preview'
        criteria = criteria.in(daily_report_group_id: @cur_user.groups.in_group(@cur_site).pluck(:id))
        criteria = criteria.where(year: @cur_site.fiscal_year)
      end
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def check_cur_month
    raise '404' if @cur_month < @active_year_range.first || @active_year_range.last < @cur_month
  end

  def set_groups
    @groups = @cur_user.groups.in_group(@cur_site)
  end

  def set_users
    @users = Gws::User.site(@cur_site).
      active.
      readable_users(@cur_user, site: @cur_site)
  end

  def set_items
    return @items if @items

    set_search_params
    @items = @model.site(@cur_site).without_deleted.and_month(@cur_month).search(@s)
    @items = @items.where(daily_report_group_id: @s[:group]) if @s[:group].present?
    @items = @items.where(user_id: @s[:user]) if @s[:user].present?

    return if @model.allowed?(:manage_all, @cur_user, site: @cur_site)

    if @model.allowed?(:manage_private, @cur_user, site: @cur_site) &&
       @cur_site.fiscal_year(@cur_month) == @cur_site.fiscal_year
      @items = @items.and_groups(@cur_user.groups.in_group(@cur_site))
    else
      @items = @items.and_user(@cur_user)
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
      redirect_to gws_daily_report_reports_path
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

  def group_options
    @groups.map { |g| [g.section_name, g.id] }
  end

  public

  def index
    if params[:s].blank?
      @s[:group] ||= @cur_group.id
      @s[:user] ||= @cur_user.id
      @items = @items.where(daily_report_group_id: @s[:group])
      @items = @items.where(user_id: @s[:user])
    end
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
    set_item
    render layout: 'ss/print'
  end

  def download_all_comments
    set_selected_items

    filename = "daily_report_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    options = { encoding: "UTF-8" }
    send_enum(
      @items.enum_csv(site: @cur_site, user: @cur_user, options: options),
      type: "text/csv; charset=#{options[:encoding]}", filename: filename
    )
  end
end
