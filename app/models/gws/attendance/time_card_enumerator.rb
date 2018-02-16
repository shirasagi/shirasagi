class Gws::Attendance::TimeCardEnumerator < Enumerator

  def initialize(site, time_cards, params)
    @cur_site = site
    @time_cards = time_cards.dup
    @params = params

    @break_times = SS.config.gws.attendance['max_break'].times.to_a.select do |i|
      @cur_site["attendance_break_time#{i + 1}_state"] == 'show'
    end

    super() do |y|
      y << bom + encode(headers.to_csv)
      @time_cards.each do |time_card|
        enum_record(y, time_card)
      end
    end
  end

  def headers
    terms = []
    terms << Gws::User.t(:uid)
    terms << Gws::User.t(:name)
    terms << Gws::Attendance::Record.t(:date)
    enter_label = (@cur_site.attendance_enter_label.presence || Gws::Attendance::Record.t(:enter))
    leave_label = (@cur_site.attendance_leave_label.presence || Gws::Attendance::Record.t(:leave))
    terms << enter_label
    terms << leave_label
    terms << "#{enter_label}#{Gws::Attendance::History.t(:created)}"
    terms << "#{enter_label}#{Gws::Attendance::History.t(:reason)}"
    terms << "#{leave_label}#{Gws::Attendance::History.t(:created)}"
    terms << "#{leave_label}#{Gws::Attendance::History.t(:reason)}"
    @break_times.each do |i|
      break_enter_label = @cur_site["attendance_break_enter#{i + 1}_label"].presence
      break_enter_label ||= I18n.t('gws/attendance.formats.break_enter', count: i + 1)
      break_leave_label = @cur_site["attendance_break_leave#{i + 1}_label"].presence
      break_leave_label ||= I18n.t('gws/attendance.formats.break_enter', count: i + 1)
      terms << break_enter_label
      terms << break_leave_label
      terms << "#{break_enter_label}#{Gws::Attendance::History.t(:created)}"
      terms << "#{break_enter_label}#{Gws::Attendance::History.t(:reason)}"
      terms << "#{break_leave_label}#{Gws::Attendance::History.t(:created)}"
      terms << "#{break_leave_label}#{Gws::Attendance::History.t(:reason)}"
    end
    terms << Gws::Attendance::Record.t(:memo)
    terms
  end

  private

  def enum_record(y, time_card)
    date = time_card.date.beginning_of_month
    terms = []

    put_history_p = proc do |history|
      if history.present? && history.reason.present?
        terms << history.created.try(:strftime, '%Y/%m/%d %H:%M')
        terms << history.reason
      else
        terms << nil
        terms << nil
      end
    end

    while date < time_card.date.end_of_month
      if include_range?(date)
        record = time_card.records.where(date: date).first
        terms.clear

        terms << time_card.user.uid
        terms << time_card.user.name
        terms << date.to_date.iso8601
        terms << format_time(date, record.try(:enter))
        terms << format_time(date, record.try(:leave))
        put_history_p.call(record.try(:find_latest_history, 'enter'))
        put_history_p.call(record.try(:find_latest_history, 'leave'))
        @break_times.each do |i|
          terms << format_time(date, record.try("break_enter#{i + 1}"))
          terms << format_time(date, record.try("break_leave#{i + 1}"))
          put_history_p.call(record.try(:find_latest_history, "break_enter#{i + 1}"))
          put_history_p.call(record.try(:find_latest_history, "break_leave#{i + 1}"))
        end
        terms << record.try(:memo)

        y << encode(terms.to_csv)
      end

      date += 1.day
    end
  end

  def include_range?(date)
    return false if @params.from_date.present? && date < @params.from_date
    return false if @params.to_date.present? && date > @params.to_date
    true
  end

  def bom
    return '' if @params.encoding == 'Shift_JIS'
    "\uFEFF"
  end

  def encode(str)
    return '' if str.blank?

    str = str.encode('CP932', invalid: :replace, undef: :replace) if @params.encoding == 'Shift_JIS'
    str
  end

  def format_time(date, time)
    return nil if time.blank?

    time = time.localtime
    hour = time.hour
    if date.day != time.day
      hour += 24
    end
    "#{hour}:#{format('%02d', time.min)}"
  end
end
