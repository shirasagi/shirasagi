module Gws::Attendance::TimeCardFilter
  extend ActiveSupport::Concern

  included do
    model Gws::Attendance::TimeCard

    helper_method :format_time, :hour_options, :minute_options
    helper_method :holiday?
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

  def format_time(date, time)
    return '--:--' if time.blank?

    time = time.in_time_zone
    hour = time.hour
    if date.day != time.day
      hour += 24
    end
    "#{hour}:#{format('%02d', time.min)}"
  end

  def hour_options
    start_hour = @cur_site.attendance_time_changed_minute / 60
    first_part = (start_hour..24).map { |h| [ I18n.t('gws/attendance.hour', count: h), h ] }
    last_part = (1..(start_hour - 1)).map { |h| h + 24 }.map { |h| [ I18n.t('gws/attendance.hour', count: h), h ] }
    first_part + last_part
  end

  def minute_options
    60.times.to_a.map { |m| [ I18n.t('gws/attendance.minute', count: m), m ] }
  end

  def holiday?(date)
    return true if HolidayJapan.check(date.localtime.to_date)

    Gws::Schedule::Holiday.site(@cur_site).
      and_public.
      allow(:read, @cur_user, site: @cur_site).
      search(start: date, end: date).present?
  end

  def well_known_types
    @_well_known_types ||= begin
      types = %w(enter leave)
      SS.config.gws.attendance['max_break'].times do |i|
        types << "break_enter#{i + 1}"
        types << "break_leave#{i + 1}"
      end
      types
    end
  end

  public

  def time
    index = well_known_types.find_index(params[:type])
    raise '404' if index.blank?

    @type = well_known_types[index]
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
      @item.histories.create(date: @cur_date, field_name: @type, action: 'modify', time: time, reason: @cell.in_reason)
      @record.send("#{@type}=", time)
      result = @record.save
    end

    if result
      location = crud_redirect_url || { action: :index }
      location = url_for(location) if location.is_a?(Hash)
      notice = t('ss.notice.saved')

      flash[:notice] = notice
      render json: { location: location }, status: :ok, content_type: json_content_type
    else
      render template: 'time', layout: false, status: :unprocessable_entity
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
end
