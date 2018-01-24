class Gws::Attendance::TimeCardEnumerator < Enumerator

  def initialize(site, time_cards, encoding)
    @cur_site = site
    @time_cards = time_cards.dup
    @encoding = encoding

    super() do |y|
      y << bom + encode(headers.to_csv)
      @time_cards.each do |time_card|
        enum_record(y, time_card)
      end
    end
  end

  def headers
    %w(ユーザID ユーザ名 日付 出勤時刻 退勤時刻 在校時間 出勤修正時刻 出勤時刻修正理由 退勤修正時刻 退勤時刻修正理由 備考)
  end

  private

  def enum_record(y, time_card)
    date = time_card.date.beginning_of_month
    while date < time_card.date.end_of_month
      record = time_card.records.where(date: date).first
      if record
        enter_history = record.find_latest_history('enter')
        leave_history = record.find_latest_history('leave')
      end

      terms = []
      terms << time_card.user.uid
      terms << time_card.user.name
      terms << date.to_date.iso8601
      terms << record.try(:enter).try(:strftime, '%H:%M')
      terms << record.try(:leave).try(:strftime, '%H:%M')
      terms << record.try(:calc_working_time).try(:strftime, '%H:%M')
      terms << enter_history.try(:created).try(:strftime, '%Y/%m/%d %H:%M')
      terms << enter_history.try(:reason)
      terms << leave_history.try(:created).try(:strftime, '%Y/%m/%d %H:%M')
      terms << leave_history.try(:reason)
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
