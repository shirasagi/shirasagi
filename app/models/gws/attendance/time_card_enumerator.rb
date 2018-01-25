class Gws::Attendance::TimeCardEnumerator < Enumerator

  def initialize(site, time_cards, encoding)
    @cur_site = site
    @time_cards = time_cards.dup
    @encoding = encoding

    @break_times = SS.config.gws.attendance['max_break'].times.to_a.select do |i|
      @cur_site["attendance_break_time_state#{i + 1}"] == 'show'
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
      break_enter_label = @cur_site["attendance_break_enter_label#{i + 1}"].presence
      break_enter_label ||= I18n.t('gws/attendance.formats.break_enter', count: i + 1)
      break_leave_label = @cur_site["attendance_break_leave_label#{i + 1}"].presence
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
      record = time_card.records.where(date: date).first
      terms.clear

      terms << time_card.user.uid
      terms << time_card.user.name
      terms << date.to_date.iso8601
      terms << record.try(:enter).try(:strftime, '%H:%M')
      terms << record.try(:leave).try(:strftime, '%H:%M')
      put_history_p.call(record.try(:find_latest_history, 'enter'))
      put_history_p.call(record.try(:find_latest_history, 'leave'))
      @break_times.each do |i|
        terms << record.try("break_enter#{i + 1}").try(:strftime, '%H:%M')
        terms << record.try("break_leave#{i + 1}").try(:strftime, '%H:%M')
        put_history_p.call(record.try(:find_latest_history, "break_enter#{i + 1}"))
        put_history_p.call(record.try(:find_latest_history, "break_leave#{i + 1}"))
      end
      terms << record.try(:memo)

      y << encode(terms.to_csv)

      date += 1.day
    end
  end

  def bom
    return '' if @encoding == 'Shift_JIS'
    "\uFEFF"
  end

  def encode(str)
    return '' if str.blank?

    str = str.encode('CP932', invalid: :replace, undef: :replace) if @encoding == 'Shift_JIS'
    str
  end
end
