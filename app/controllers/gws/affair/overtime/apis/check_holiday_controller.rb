class Gws::Affair::Overtime::Apis::CheckHolidayController < ApplicationController
  include Gws::ApiFilter

  def index
    @target_user = Gws::User.find(params[:uid])

    @date = Date.parse(params[:year_month_day]) rescue nil
    @date ||= Time.zone.today

    @duty_calendar = @target_user.effective_duty_calendar(@cur_site)
    render json: {
      date: @date,
      holiday: @duty_calendar.holiday?(@date),
      weekly_leave_day: @duty_calendar.weekly_leave_day?(@date),
      leave_day: @duty_calendar.leave_day?(@date)
    }.to_json
  end
end
