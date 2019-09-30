module Gws::Attendance::TimeCardFilter
  extend ActiveSupport::Concern

  included do
    model Gws::Attendance::TimeCard

    helper_method :format_time, :day_options, :hour_options, :minute_options, :reason_type_options
    helper_method :leave_day?, :weekly_leave_day?, :holiday?
  end

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
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
  end

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

  def hour_options
    start_hour = @duty_calendar.attendance_time_changed_minute / 60
    first_part = (start_hour..24).map { |h| [ I18n.t('gws/attendance.hour', count: h), h ] }
    last_part = (1..(start_hour - 1)).map { |h| h + 24 }.map { |h| [ I18n.t('gws/attendance.hour', count: h), h ] }
    first_part + last_part
  end

  def minute_options
    60.times.to_a.map { |m| [ I18n.t('gws/attendance.minute', count: m), m ] }
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

  WELL_KNOWN_TYPES = begin
    types = %w(enter leave)
    SS.config.gws.attendance['max_break'].times do |i|
      types << "break_enter#{i + 1}"
      types << "break_leave#{i + 1}"
    end
    types.freeze
  end

  public

  def time
    index = WELL_KNOWN_TYPES.find_index(params[:type])
    raise '404' if index.blank?

    @type = WELL_KNOWN_TYPES[index]
    @model = Gws::Attendance::TimeEdit

    if request.get? || request.head?
      @cell = @model.new
      render template: 'time', layout: false
      return
    end

    @cell = @model.new params.require(:cell).permit(@model.permitted_fields).merge(fix_params)
    result = false
    if @cell.valid?
      time = @cell.calc_time(@cur_date)
      @item.histories.create(
        date: @cur_date, field_name: @type, action: 'modify',
        time: time, reason_type: @cell.in_reason_type, reason: @cell.in_reason
      )
      @record.duty_calendar = @duty_calendar
      @record.send("#{@type}=", time)
      result = @record.save
    end

    if result
      location = crud_redirect_url || { action: :index }
      location = url_for(location) if location.is_a?(Hash)
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
        format.html { render template: 'time', layout: false, status: :unprocessable_entity }
        format.json { render json: @cell.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end

  def memo
    if request.get? || request.head?
      render template: 'memo', layout: false
      return
    end

    safe_params = params.require(:record).permit(:memo)
    @record.memo = safe_params[:memo]

    location = crud_redirect_url || { action: :index }
    if @record.save
      notice = t('ss.notice.saved')
    else
      notice = @record.errors.full_messages.join("\n")
    end
    redirect_to location, notice: notice
  end

  def working_time
    if request.get?
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
