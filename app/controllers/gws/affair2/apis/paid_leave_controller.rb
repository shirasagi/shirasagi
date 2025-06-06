class Gws::Affair2::Apis::PaidLeaveController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair2::PaidLeaveSetting

  before_action :set_setting

  def set_setting
    date = Time.zone.parse(params[:date]) rescue nil
    raise "404" if date.nil?

    user = Gws::User.find(params[:user])
    file_id = params[:file_id].to_i

    @attendance_setting = Gws::Affair2::AttendanceSetting.current_setting(@cur_site, user, date)
    return if @attendance_setting.nil?

    @duty_setting = @attendance_setting.duty_setting
    return if @duty_setting.nil?

    @paid_leave_setting = @attendance_setting.paid_leave_settings.where(year: date.year).first
    return if @paid_leave_setting.nil?

    @paid_leave_setting.without_file_id = file_id
  end

  def index
    if @attendance_setting.nil? || @duty_setting.nil? || @paid_leave_setting.nil?
      render plain: "年次有給が設定されていません"
      return
    end
    render plain: "有効時間: #{@paid_leave_setting.remind_minutes_label(@duty_setting.day_leave_minutes)}"
  end
end
