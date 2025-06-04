module Gws::Affair2::BaseFilter
  extend ActiveSupport::Concern

  included do
    delegate :format_time, :format_minutes, :format_minutes2, to: Gws::Affair2::Utils

    before_action :set_attendance_date
    before_action :set_attendance
    helper_method :format_time, :format_minutes, :format_minutes2, :attendance_date?
  end

  private

  def required_attendance
    false
  end

  def set_attendance_date
    @attendance_date = @cur_site.affair2_attendance_date
    @attendance_year_month = @attendance_date.strftime('%Y%m')
  end

  def set_attendance
    @cur_attendance = Gws::Affair2::AttendanceSetting.current_setting(@cur_site, @cur_user, Time.zone.now)
    if required_attendance && @cur_attendance.nil?
      @crumbs = [[@cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path]]
      @hide_menu_view = true
      @hide_content_navi_view = true
      render template: "gws/affair2/attendance/errors/attendance"
      return
    end

    if @cur_attendance
      @cur_duty = @cur_attendance.duty_setting
      @cur_leave = @cur_attendance.leave_setting
    end
  end

  def attendance_date?(date)
    date.to_date == @attendance_date.to_date
  end
end
