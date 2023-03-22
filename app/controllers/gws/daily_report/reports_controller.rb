class Gws::DailyReport::ReportsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::DailyReport::Report

  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_search_params
  before_action :set_active_year_range
  before_action :set_cur_month
  before_action :check_cur_month
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :soft_delete]

  helper_method :year_month_options, :group_options

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
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

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6

    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
  end

  def set_active_year_range
    @active_year_range ||= begin
      items = @model.unscoped.site(@cur_site).without_deleted.search(@s).order_by(daily_report_date: 1)
      start_date = [Time.zone.now]
      start_date << items.first.daily_report_date if items.first.try(:daily_report_date).present?
      start_date = @cur_site.
        fiscal_first_date(@cur_site.fiscal_year(start_date.min)).
        beginning_of_month
      end_date = [Time.zone.now]
      end_date << items.last.daily_report_date if items.last.try(:daily_report_date).present?
      end_date = @cur_site.
        fiscal_last_date(@cur_site.fiscal_year(end_date.max)).
        beginning_of_month
      [start_date, end_date]
    end
  end

  def check_cur_month
    raise '404' if @cur_month < @active_year_range.first || @active_year_range.last < @cur_month
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

  def download_comment
    set_item

    filename = "daily_report_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    encoding = "Shift_JIS"
    send_enum(@item.enum_csv(user: @cur_user, encoding: encoding), type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def download_all_comments
    set_selected_items

    filename = "daily_report_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    encoding = "Shift_JIS"
    send_enum(
      @items.enum_csv(site: @cur_site, user: @cur_user, encoding: encoding),
      type: "text/csv; charset=#{encoding}", filename: filename
    )
  end

  def download_attachment
    set_item

    files = @item.collect_attachments
    if files.blank?
      redirect_to({ action: :show }, { notice: t("gws/workflow.notice.no_files") })
      return
    end

    filename = "daily_report_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip"
    zip = Gws::Compressor.new(@cur_user, items: files, filename: filename)
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename)

    if zip.deley_download?
      job = Gws::CompressJob.bind(site_id: @cur_site, user_id: @cur_user)
      job.perform_later(zip.serialize)

      flash[:notice_options] = { timeout: 0 }
      redirect_to({ action: :show }, { notice: zip.delay_message })
    else
      raise '500' unless zip.save
      send_file(zip.path, type: zip.type, filename: zip.name, disposition: 'attachment', x_sendfile: true)
    end
  end

  def download_all_attachments
    set_selected_items

    files = @items.collect_attachments
    if files.blank?
      redirect_to({ action: :index }, { notice: t("gws/workflow.notice.no_files") })
      return
    end

    filename = "daily_report_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip"
    zip = Gws::Compressor.new(@cur_user, items: files, filename: filename)
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename)

    if zip.deley_download?
      job = Gws::CompressJob.bind(site_id: @cur_site, user_id: @cur_user)
      job.perform_later(zip.serialize)

      flash[:notice_options] = { timeout: 0 }
      redirect_to({ action: :index }, { notice: zip.delay_message })
    else
      raise '500' unless zip.save
      send_file(zip.path, type: zip.type, filename: zip.name, disposition: 'attachment', x_sendfile: true)
    end
  end
end
