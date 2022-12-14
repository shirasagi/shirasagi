module Gws::Affair::Attendance::TimeCardFilter
  extend ActiveSupport::Concern
  include Gws::Attendance::TimeCardFilter

  included do
    model Gws::Attendance::TimeCard

    helper_method :holiday?, :leave_day?, :weekly_leave_day?
    helper_method :reason_type_options, :day_options
  end

  private

  def set_overtime_files
    @overtime_files = {}
    Gws::Affair::OvertimeFile.site(@cur_site).where(target_user_id: @item.user_id).and(
      { "state" => "approve" },
      { "date" => { "$gte" => @cur_month } },
      { "date" => { "$lte" => @cur_month.end_of_month } }
    ).each do |item|
      date = item.date.localtime.to_date
      @overtime_files[date] ||= []
      @overtime_files[date] << item
    end
  end

  def set_leave_files
    @leave_files = {}
    Gws::Affair::LeaveFile.site(@cur_site).where(target_user_id: @item.user_id, state: "approve").or([
      { "end_at" => { "$gte" => @cur_month } },
      { "start_at" => { "$lt" => @cur_month.advance(months: 1) } }
    ]).each do |item|
      item.leave_dates.each do |leave_date|
        @leave_files[leave_date.date.to_date] ||= []
        @leave_files[leave_date.date.to_date] << item
      end
    end
  end

  def format_time(date, time)
    return '--:--' if time.blank?

    time = time.in_time_zone
    hour = time.hour
    label = ""
    attendance_date = @duty_calendar.calc_attendance_date(time)

    day_diff = (time.to_date - date.to_date).to_i
    if attendance_date > date.beginning_of_day
      label = "翌"
      day_diff -= 1
    end
    hour += day_diff * 24 if day_diff > 0

    "#{label}#{hour}:#{format('%02d', time.min)}"
  end

  def day_options
    I18n.t("gws/attendance.options.in_day").map { |k, v| [v, k] }
  end

  def reason_type_options
    I18n.t("gws/attendance.options.reason_type").map { |k, v| [v, k] }
  end

  # 休み
  def leave_day?(date)
    @duty_calendar.leave_day?(date)
  end

  # 週休日
  def weekly_leave_day?(date)
    @duty_calendar.weekly_leave_day?(date)
  end

  # 祝日
  def holiday?(date)
    @duty_calendar.holiday?(date)
  end

  public

  def working_time
    if request.get? || request.head?
      render template: 'working_time', layout: false
      return
    end

    safe_params = params.require(:record).permit(:working_hour, :working_minute)
    @record.working_hour = safe_params[:working_hour].presence
    @record.working_minute = safe_params[:working_minute].presence

    result = @record.save
    if result
      location = crud_redirect_url || url_for(action: :index)
      notice = t('ss.notice.saved')

      respond_to do |format|
        flash[:notice] = notice
        format.html do
          if request.xhr?
            render json: { location: location }, status: :ok, content_type: json_content_type
          else
            redirect_to location
          end
        end
        format.json { render json: { location: location }, status: :ok, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { render template: 'working_time', layout: false, status: :unprocessable_entity }
        format.json { render json: @cell.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end
end
