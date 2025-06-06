class Gws::Affair2::Overtime::Achieve < Gws::Affair2::Loader::Monthly::Base
  include Gws::Affair2::SubGroupPermission

  set_permission_name "gws_affair2_overtime_achieves"

  attr_reader :site, :user, :group, :month,
    :attendance_setting, :duty_setting

  #validate :validate_attendance_setting

  def initialize(site, user, group, month)
    @site = site
    @user = user
    @group = group
    @month = month

    time_card = Gws::Affair2::Attendance::TimeCard.site(site).user(user).
      where(date: month).first
    super(time_card)
  end

  #def set_attendance_setting
  #  # 対象年の最新の出退勤設定を参照する
  #  @attendance_setting = Gws::Affair2::AttendanceSetting.site(@site).user(@user).
  #    and_between(start_date, close_date).first
  #  return if @attendance_setting.nil?
  #
  #  @duty_setting = @attendance_setting.duty_setting
  #  @paid_leave_setting = @attendance_setting.paid_leave_settings.where(year: month.year).first
  #end

  #def validate_attendance_setting
  #  if @attendance_setting.nil?
  #    errors.add :base, "出退勤設定がありません。"
  #    return
  #  end
  #  if @duty_setting.nil?
  #    errors.add :base, "雇用区分設定がありません。"
  #    return
  #  end
  #end
end
