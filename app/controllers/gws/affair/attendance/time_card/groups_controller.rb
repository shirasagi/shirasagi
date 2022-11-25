class Gws::Affair::Attendance::TimeCard::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  include Gws::Affair::Attendance::TimeCardFilter

  menu_view nil
  navi_view "gws/affair/main/navi"

  before_action :check_model_permission
  before_action :set_cur_month, except: %i[main]
  before_action :set_cur_day, except: %i[main]
  helper_method :year_month_options, :day_options, :group_options
  helper_method :next_day, :prev_day
  helper_method :manageable_time_card?

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t('modules.gws/affair/attendance/time_card'), gws_affair_attendance_time_card_main_path]
    @crumbs << [t('modules.gws/affair/attendance/time_card/group'), action: :index]
  end

  def set_cur_day
    raise '404' if params[:day].blank?

    day = params[:day].to_i
    day = 1 if day < 1 || day > @cur_month.end_of_month.day
    @cur_day = @cur_month.change(day: day)
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

  def day_options
    (1..@cur_month.end_of_month.day).map do |day|
      [I18n.t("gws/attendance.day", count: day), day]
    end
  end

  def group_options
    @groups.map do |group|
      [group.name, group.id]
    end
  end

  def next_day
    @next_day ||= begin
      date = @cur_day.advance(days: 1)
      if date > @active_year_range.last.end_of_month
        false
      else
        url_for({ action: :index, year_month: date.strftime('%Y%m'), day: date.day, group_id: @group.id })
      end
    end
  end

  def prev_day
    @prev_day ||= begin
      date = @cur_day.advance(days: -1)
      if date < @active_year_range.first
        false
      else
        url_for({ action: :index, year_month: date.strftime('%Y%m'), day: date.day, group_id: @group.id })
      end
    end
  end

  def format_time(date, time, user)
    return '--:--' if time.blank?

    time = time.in_time_zone
    hour = time.hour
    label = ""
    attendance_date = user.effective_duty_calendar(@cur_site).calc_attendance_date(time)

    day_diff = (time.to_date - date.to_date).to_i
    if attendance_date > date.beginning_of_day
      label = I18n.t("gws/attendance.next_mark")
      day_diff -= 1
    end
    hour += day_diff * 24 if day_diff > 0

    "#{label}#{hour}:#{format('%02d', time.min)}"
  end

  # 休み
  def leave_day?(date, user)
    user.effective_duty_calendar(@cur_site).leave_day?(date)
  end

  # 週休日
  def weekly_leave_day?(date, user)
    user.effective_duty_calendar(@cur_site).weekly_leave_day?(date)
  end

  # 祝日
  def holiday?(date, user)
    user.effective_duty_calendar(@cur_site).holiday?(date)
  end

  def set_groups
    if @model.allowed?(:aggregate_all, @cur_user, site: @cur_site, permission_name: attendance_permission_name)
      @groups = Gws::Group.in_group(@cur_site).active
    elsif @model.allowed?(:aggregate_private, @cur_user, site: @cur_site, permission_name: attendance_permission_name)
      @groups = Gws::Group.in_group(@cur_group).active
    else
      @groups = Gws::Group.none
    end

    @group = @groups.to_a.select { |group| group.id == params[:group_id].to_i }.first
    @group ||= @cur_group
  end

  def set_overtime_files
    @overtime_files = {}
    Gws::Affair::OvertimeFile.site(@cur_site).in(target_user_id: @users.map(&:id)).and(
      { "state" => "approve" },
      { "date" => @cur_day }
    ).each do |item|
      @overtime_files[item.target_user_id] ||= []
      @overtime_files[item.target_user_id] << item
    end
  end

  def set_leave_files
    @leave_files = {}
    Gws::Affair::LeaveFile.site(@cur_site).where(state: "approve").
      in(target_user_id: @users.map(&:id)).
      in("leave_dates.date" => @cur_day).each do |item|
      @leave_files[item.target_user_id] ||= []
      @leave_files[item.target_user_id] << item
    end
  end

  def check_model_permission
    raise "403" unless %i[aggregate_private aggregate_all].any? { |priv| @model.allowed?(priv, @cur_user, site: @cur_site, permission_name: attendance_permission_name) }
  end

  def manageable_time_card?
    @_manageable_time_card ||= %i[manage_private manage_all].any? do |priv|
      @model.allowed?(priv, @cur_user, site: @cur_site, permission_name: attendance_permission_name)
    end
  end

  public

  def main
    today = @cur_site.calc_attendance_date(Time.zone.now)
    redirect_to "#{request.path}/#{today.strftime('%Y%m')}/#{today.day}"
  end

  def index
    set_groups

    @users = Gws::User.active.in(group_ids: @group.id).order_by_title(@cur_site)
    @items = @model.site(@cur_site).in(user_id: @users.map(&:id)).
      where(date: @cur_day.change(day: 1)).
      index_by(&:user_id)
    set_overtime_files
    set_leave_files
  end
end
