class Gws::Attendance::Management::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Attendance::TimeCard

  before_action :check_model_permission
  before_action :set_groups
  before_action :set_active_year_range
  before_action :set_cur_month
  before_action :set_search_params
  before_action :set_items
  before_action :set_item, only: %i[show edit update delete destroy]

  helper_method :year_month_options, :group_options

  private

  def set_crumbs
    @crumbs << [t('modules.gws/attendance'), gws_attendance_main_path]
    @crumbs << [t('ss.management'), gws_attendance_management_main_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def check_model_permission
    raise "403" unless %i[manage_private manage_all].any? { |priv| @model.allowed?(priv, @cur_user, site: @cur_site) }
  end

  def set_groups
    if @model.allowed?(:manage_all, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_site).active
    elsif @model.allowed?(:manage_private, @cur_user, site: @cur_site)
      @groups = @cur_user.groups.active
    else
      @groups = Gws::Group.none
    end
  end

  def set_active_year_range
    @active_year_range ||= begin
      end_date = Time.zone.now.beginning_of_month

      start_date = end_date
      start_date -= 1.month while start_date.month != @cur_site.attendance_year_changed_month
      start_date -= @cur_site.attendance_management_year.years

      [start_date, end_date]
    end
  end

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6

    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")

    raise '404' if @cur_month < @active_year_range.first || @active_year_range.last < @cur_month
  end

  def set_search_params
    @s = OpenStruct.new(params[:s])
    if @s.group_id.present?
      @s.group = @groups.find(@s.group_id) rescue nil
    end
  end

  def set_items
    @items ||= begin
      criteria = @model.site(@cur_site).where(date: @cur_month).search(@s)
      criteria = criteria.in_groups(@groups)
      criteria
    end
  end

  def set_item
    @item = @items.find(params[:id])
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

  def download
    if request.get?
      user_ids = @items.pluck(:user_id)
      @target_users = Gws::User.in(id: user_ids).active
      if @target_users.blank?
        redirect_to({ action: :index, s: params[:s] }, { notice: t('gws/attendance.no_target_users') })
      end
      return
    end

    safe_params = params.require(:item).permit(:encoding)
    encoding = safe_params[:encoding]
    filename = "time_cards_#{Time.zone.now.to_i}.csv"
    send_enum(@items.enum_csv(@cur_site, encoding), type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def lock
    if request.get?
      user_ids = @items.and_unlocked.pluck(:user_id)
      @target_users = Gws::User.in(id: user_ids).active
      if @target_users.blank?
        redirect_to({ action: :index, s: params[:s] }, { notice: t('gws/attendance.no_target_users') })
      end
      return
    end

    safe_params = params.require(:item).permit(user_ids: [])
    user_ids = Gws::User.in(id: safe_params[:user_ids]).active.pluck(:id)
    render_update @items.in(user_id: user_ids).lock_all, location: { action: :index }, render: { file: :lock }
  end

  def unlock
    if request.get?
      user_ids = @items.and_locked.pluck(:user_id)
      @target_users = Gws::User.in(id: user_ids).active
      if @target_users.blank?
        redirect_to({ action: :index, s: params[:s] }, { notice: t('gws/attendance.no_target_users') })
      end
      return
    end

    safe_params = params.require(:item).permit(user_ids: [])
    user_ids = Gws::User.in(id: safe_params[:user_ids]).active.pluck(:id)
    render_update @items.in(user_id: user_ids).unlock_all, location: { action: :index }, render: { file: :unlock }
  end
end
