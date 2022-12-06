module Gws::Affair::OvertimeFile::Compensatory
  extend ActiveSupport::Concern

  included do
    # 週内振替
    attr_accessor :week_in_start_at_date, :week_in_start_at_hour, :week_in_start_at_minute
    attr_accessor :week_in_end_at_date, :week_in_end_at_hour, :week_in_end_at_minute

    has_one :week_in_leave_file, class_name: "Gws::Affair::LeaveFile", inverse_of: :week_in_compensatory_file

    field :week_in_start_at, type: DateTime
    field :week_in_end_at, type: DateTime
    field :week_in_compensatory_minute, type: Integer, default: 0

    permit_params :week_in_start_at_date, :week_in_start_at_hour, :week_in_start_at_minute
    permit_params :week_in_end_at_date, :week_in_end_at_hour, :week_in_end_at_minute
    permit_params :week_in_compensatory_minute

    # 週外振替
    attr_accessor :week_out_start_at_date, :week_out_start_at_hour, :week_out_start_at_minute
    attr_accessor :week_out_end_at_date, :week_out_end_at_hour, :week_out_end_at_minute

    has_one :week_out_leave_file, class_name: "Gws::Affair::LeaveFile", inverse_of: :week_out_compensatory_file

    field :week_out_start_at, type: DateTime
    field :week_out_end_at, type: DateTime
    field :week_out_compensatory_minute, type: Integer, default: 0

    permit_params :week_out_start_at_date, :week_out_start_at_hour, :week_out_start_at_minute
    permit_params :week_out_end_at_date, :week_out_end_at_hour, :week_out_end_at_minute
    permit_params :week_out_compensatory_minute

    # 代休振替
    attr_accessor :holiday_compensatory_start_at_date, :holiday_compensatory_start_at_hour, :holiday_compensatory_start_at_minute
    attr_accessor :holiday_compensatory_end_at_date, :holiday_compensatory_end_at_hour, :holiday_compensatory_end_at_minute

    has_one :holiday_compensatory_leave_file, class_name: "Gws::Affair::LeaveFile", inverse_of: :holiday_compensatory_file

    field :holiday_compensatory_start_at, type: DateTime
    field :holiday_compensatory_end_at, type: DateTime
    field :holiday_compensatory_minute, type: Integer, default: 0

    permit_params :holiday_compensatory_start_at_date, :holiday_compensatory_start_at_hour, :holiday_compensatory_start_at_minute
    permit_params :holiday_compensatory_end_at_date, :holiday_compensatory_end_at_hour, :holiday_compensatory_end_at_minute
    permit_params :holiday_compensatory_minute

    after_initialize :initialize_start_end
    after_initialize :initialize_week_in
    after_initialize :initialize_week_out
    after_initialize :initialize_week_holiday
  end

  private

  def initialize_start_end
    if start_at
      self.start_at_date = start_at.strftime("%Y/%m/%d")
      self.start_at_hour = start_at.hour
      self.start_at_minute = start_at.minute
    end
    if end_at
      self.end_at_date = end_at.strftime("%Y/%m/%d")
      self.end_at_hour = end_at.hour
      self.end_at_minute = end_at.minute
    end
  end

  def initialize_week_in
    if week_in_start_at
      self.week_in_start_at_date = week_in_start_at.strftime("%Y/%m/%d")
      self.week_in_start_at_hour = week_in_start_at.hour
      self.week_in_start_at_minute = week_in_start_at.minute
    end
    if week_in_end_at
      self.week_in_end_at_date = week_in_end_at.strftime("%Y/%m/%d")
      self.week_in_end_at_hour = week_in_end_at.hour
      self.week_in_end_at_minute = week_in_end_at.minute
    end
  end

  def initialize_week_out
    if week_out_start_at
      self.week_out_start_at_date = week_out_start_at.strftime("%Y/%m/%d")
      self.week_out_start_at_hour = week_out_start_at.hour
      self.week_out_start_at_minute = week_out_start_at.minute
    end
    if week_out_end_at
      self.week_out_end_at_date = week_out_end_at.strftime("%Y/%m/%d")
      self.week_out_end_at_hour = week_out_end_at.hour
      self.week_out_end_at_minute = week_out_end_at.minute
    end
  end

  def initialize_week_holiday
    if holiday_compensatory_start_at
      self.holiday_compensatory_start_at_date = holiday_compensatory_start_at.strftime("%Y/%m/%d")
      self.holiday_compensatory_start_at_hour = holiday_compensatory_start_at.hour
      self.holiday_compensatory_start_at_minute = holiday_compensatory_start_at.minute
    end
    if holiday_compensatory_end_at
      self.holiday_compensatory_end_at_date = holiday_compensatory_end_at.strftime("%Y/%m/%d")
      self.holiday_compensatory_end_at_hour = holiday_compensatory_end_at.hour
      self.holiday_compensatory_end_at_minute = holiday_compensatory_end_at.minute
    end
  end

  def reset_compensatory
    self.week_in_start_at = nil
    self.week_in_end_at = nil
    self.week_in_compensatory_minute = 0

    self.week_out_start_at = nil
    self.week_out_end_at = nil
    self.week_out_compensatory_minute = 0

    self.holiday_compensatory_start_at = nil
    self.holiday_compensatory_end_at = nil
    self.holiday_compensatory_minute = 0
  end

  def parse_dhm(date, hour, minute)
    return if date.blank? || hour.blank? || minute.blank?
    Time.zone.parse("#{date} #{hour}:#{minute}")
  end

  def validate_compensatory_minute
    self.week_in_compensatory_minute = week_in_compensatory_minute.to_i
    self.week_out_compensatory_minute = week_out_compensatory_minute.to_i
    self.holiday_compensatory_minute = holiday_compensatory_minute.to_i

    # 振替は同時申請不可
    if [week_in_compensatory_minute, week_out_compensatory_minute, holiday_compensatory_minute].count { |v| v > 0 } > 1
      errors.add :base, :duplicate_compensatory_minute
    end

    # 振替は祝日のみ
    if holiday_compensatory_minute > 0
      user = target_user
      return if site.blank? || user.blank? || start_at.blank? || end_at.blank?

      duty_calendar = user.effective_duty_calendar(site)
      if !duty_calendar.holiday?(start_at)
        errors.add :holiday_compensatory_minute, "：代休振替は祝日のみ申請可能です。"
      end
    end
  end

  # 週内振替休暇 残業の開始〜終了
  def validate_week_in_compensatory_minute
    if week_in_compensatory_minute == 0
      self.week_in_start_at = nil
      self.week_in_end_at = nil
      return
    end

    # 残業の開始時間〜終了時間が振替時間以上（深夜残業時間帯は振替できない）
    valid_compensatory?(:week_in_compensatory_minute)

    # 週内申請は休暇を設定していなくても時間外申請できる
    if week_in_start_at_date.blank? && week_in_end_at_date.blank?
      return
    end

    if week_in_start_at_date.blank?
      errors.add :week_in_start_at, :blank
    end
    if week_in_end_at_date.blank?
      errors.add :week_in_end_at, :blank
    end
    return if errors.present?

    self.week_in_start_at = parse_dhm(week_in_start_at_date, week_in_start_at_hour, week_in_start_at_minute)
    self.week_in_end_at = parse_dhm(week_in_end_at_date, week_in_end_at_hour, week_in_end_at_minute)

    validate_week_in_compensatory_leave
  end

  # 週内振替休暇 休暇の開始〜終了
  def validate_week_in_compensatory_leave
    if week_in_start_at >= week_in_end_at
      errors.add :week_in_compensatory_minute, "：振替終了は振替開始より大きい値にしてください。"
    end
    if week_in_end_at >= week_in_start_at.advance(days: 1)
      errors.add :week_in_compensatory_minute, "：振替開始〜終了が1日を超過しています。"
    end
    if ((week_in_end_at - week_in_start_at) * 24 * 60).to_i < week_in_compensatory_minute
      label = week_in_compensatory_minute.to_f / 60
      errors.add :week_in_compensatory_minute, "：振替開始〜終了は振替時間（#{label}時間）より長く設定してください。"
    end

    # 休暇日は同一週内
    return if start_at.blank?
    start_of_week = start_at.advance(days: (-1 * start_at.wday)).change(hour: 0, min: 0, sec: 0)
    end_of_week = start_of_week.advance(days: 6)

    if week_in_start_at < start_of_week || week_in_start_at >= end_of_week.advance(days: 1)
      errors.add :week_in_compensatory_minute,
        "：振替開始が週内になっていません。（#{start_of_week.strftime("%Y/%m/%d")}〜#{end_of_week.strftime("%Y/%m/%d")}）"
    end
  end

  # 週外振替休暇 残業の開始〜終了
  def validate_week_out_compensatory_minute
    if week_out_compensatory_minute == 0
      self.week_out_start_at = nil
      self.week_out_end_at = nil
      return
    end

    # 残業の開始時間〜終了時間が振替時間以上（深夜残業時間帯は振替できない）
    valid_compensatory?(:week_out_compensatory_minute)

    # 週外申請は休暇を設定していなくても時間外申請できる
    if week_out_start_at_date.blank? && week_out_end_at_date.blank?
      return
    end

    if week_out_start_at_date.blank?
      errors.add :week_out_start_at, :blank
    end
    if week_out_end_at_date.blank?
      errors.add :week_out_end_at, :blank
    end
    return if errors.present?

    self.week_out_start_at = parse_dhm(week_out_start_at_date, week_out_start_at_hour, week_out_start_at_minute)
    self.week_out_end_at = parse_dhm(week_out_end_at_date, week_out_end_at_hour, week_out_end_at_minute)

    validate_week_out_compensatory_leave
  end

  # 週外振替休暇 休暇の開始〜終了
  def validate_week_out_compensatory_leave
    if week_out_start_at >= week_out_end_at
      errors.add :week_out_compensatory_minute, "：振替終了は振替開始より大きい値にしてください。"
    end
    if week_out_end_at >= week_out_start_at.advance(days: 1)
      errors.add :week_out_compensatory_minute, "：振替開始〜終了が1日を超過しています。"
    end
    if ((week_out_end_at - week_out_start_at) * 24 * 60).to_i < week_out_compensatory_minute
      label = week_out_compensatory_minute.to_f / 60
      errors.add :week_out_compensatory_minute, "：振替開始〜終了は振替時間（#{label}時間）より長く設定してください。"
    end

    return if start_at.blank?
    # 休暇日は同一週外
    start_of_week = start_at.advance(days: (-1 * start_at.wday)).change(hour: 0, min: 0, sec: 0)
    end_of_week = start_of_week.advance(days: 6)

    if week_out_start_at >= start_of_week && week_out_start_at < end_of_week.advance(days: 1)
      errors.add :week_out_compensatory_minute,
        "：振替開始が週外になっていません。（#{start_of_week.strftime("%Y/%m/%d")}〜#{end_of_week.strftime("%Y/%m/%d")}）"
    end

    # 休暇日が有効期限内
    if !in_week_out_compensatory_expiration?(week_out_start_at.to_date)
      errors.add :week_out_compensatory_minute,
        "：振替開始が有効期限内ではありません。（有効期限： #{week_out_compensatory_expiration_term}）"
    end
  end

  # 代休振替 残業の開始〜終了
  def validate_holiday_compensatory_minute
    if holiday_compensatory_minute == 0
      self.holiday_compensatory_start_at = nil
      self.holiday_compensatory_end_at = nil
      return
    end

    # 残業の開始時間〜終了時間が振替時間以上（深夜残業時間帯は振替できない）
    valid_compensatory?(:holiday_compensatory_minute)

    # 代休申請は休暇を設定していなくても時間外申請できる
    if holiday_compensatory_start_at_date.blank? && holiday_compensatory_end_at_date.blank?
      return
    end

    if holiday_compensatory_start_at_date.blank?
      errors.add :holiday_compensatory_start_at, :blank
    end
    if holiday_compensatory_end_at_date.blank?
      errors.add :holiday_compensatory_end_at, :blank
    end
    return if errors.present?

    self.holiday_compensatory_start_at = parse_dhm(
      holiday_compensatory_start_at_date,
      holiday_compensatory_start_at_hour,
      holiday_compensatory_start_at_minute)
    self.holiday_compensatory_end_at = parse_dhm(
      holiday_compensatory_end_at_date,
      holiday_compensatory_end_at_hour,
      holiday_compensatory_end_at_minute)

    validate_holiday_compensatory_leave
  end

  # 代休振替 休暇の開始〜終了
  def validate_holiday_compensatory_leave
    if holiday_compensatory_start_at >= holiday_compensatory_end_at
      errors.add :holiday_compensatory_minute, "：振替終了は振替開始より大きい値にしてください。"
    end
    if holiday_compensatory_end_at >= holiday_compensatory_start_at.advance(days: 1)
      errors.add :holiday_compensatory_minute, "：振替開始〜終了が1日を超過しています。"
    end
    if ((holiday_compensatory_end_at - holiday_compensatory_start_at) * 24 * 60).to_i < holiday_compensatory_minute
      label = holiday_compensatory_minute.to_f / 60
      errors.add :holiday_compensatory_minute, "：振替開始〜終了は振替時間（#{label}時間）より長く設定してください。"
    end

    return if start_at.blank?
    # 休暇日が有効期限内
    if !in_week_out_compensatory_expiration?(holiday_compensatory_start_at.to_date)
      errors.add :holiday_compensatory_minute, "：振替開始が有効期限内ではありません。（有効期限： #{week_out_compensatory_expiration_term}）"
    end
  end

  def valid_compensatory?(key)
    minute = send(key)
    user = target_user
    return if site.blank? || user.blank? || start_at.blank? || end_at.blank?

    duty_calendar = user.effective_duty_calendar(site)
    night_start_at = duty_calendar.night_time_start(start_at)
    night_end_at = duty_calendar.night_time_end(end_at)

    over_minutes, = Gws::Affair::Utils.time_range_minutes((start_at..end_at), (night_start_at..night_end_at))
    if over_minutes < minute
      label = minute.to_f / 60
      errors.add key, "：振替時間（#{label}時間）が時間外開始〜終了より長くなっています。（深夜残業時間帯を振替に含めることはできません）"
      return
    end
  end

  public

  def week_in_compensatory_minute_options
    (cur_site || site).compensatory_minute_options
  end

  def week_out_compensatory_minute_options
    (cur_site || site).compensatory_minute_options
  end

  def holiday_compensatory_minute_options
    (cur_site || site).compensatory_minute_options
  end

  def week_in_compensatory_term
    return if week_in_start_at.blank?
    week_in_start_time = "#{week_in_start_at.hour}:#{format('%02d', week_in_start_at.minute)}"
    week_in_end_time = "#{week_in_end_at.hour}:#{format('%02d', week_in_end_at.minute)}"
    if week_in_start_at_date == end_at_date
      "#{week_in_start_at.strftime("%Y/%m/%d")} #{week_in_start_time}#{I18n.t("ss.wave_dash")}#{week_in_end_time}"
    else
      "#{week_in_start_at.strftime("%Y/%m/%d")} #{week_in_start_time}#{I18n.t("ss.wave_dash")}#{week_in_end_at.strftime("%Y/%m/%d")} #{week_in_end_time}"
    end
  end

  def week_out_compensatory_term
    return if week_out_start_at.blank?
    week_out_start_time = "#{week_out_start_at.hour}:#{format('%02d', week_out_start_at.minute)}"
    week_out_end_time = "#{week_out_end_at.hour}:#{format('%02d', week_out_end_at.minute)}"
    if start_at_date == end_at_date
      "#{week_out_start_at.strftime("%Y/%m/%d")} #{week_out_start_time}#{I18n.t("ss.wave_dash")}#{week_out_end_time}"
    else
      "#{week_out_start_at.strftime("%Y/%m/%d")} #{week_out_start_time}#{I18n.t("ss.wave_dash")}#{week_out_end_at.strftime("%Y/%m/%d")} #{week_out_end_time}"
    end
  end

  def holiday_compensatory_term
    return if holiday_compensatory_start_at.blank?
    return if holiday_compensatory_end_at.blank?

    start_time = "#{holiday_compensatory_start_at.hour}:#{format('%02d', holiday_compensatory_start_at.minute)}"
    end_time = "#{holiday_compensatory_end_at.hour}:#{format('%02d', holiday_compensatory_end_at.minute)}"

    if holiday_compensatory_start_at.to_date == holiday_compensatory_end_at.to_date
      "#{holiday_compensatory_start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_time}"
    else
      "#{holiday_compensatory_start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{holiday_compensatory_end_at.strftime("%Y/%m/%d")} #{end_time}"
    end
  end

  def week_out_compensatory_expiration_start_date
    number = site.week_out_compensatory_file_start_limit
    unit = site.week_out_compensatory_file_start_limit_unit

    case unit
    when 'day'
      start_at.to_date.advance(days: -1 * number).advance(days: 1)
    when 'week'
      start_at.to_date.advance(weeks: -1 * number).advance(days: 1)
    when 'month'
      start_at.to_date.advance(months: -1 * number).advance(days: 1)
    when 'year'
      start_at.to_date.advance(years: -1 * number).advance(days: 1)
    end
  end

  def week_out_compensatory_expiration_end_date
    number = site.week_out_compensatory_file_end_limit
    unit = site.week_out_compensatory_file_end_limit_unit

    case unit
    when 'day'
      start_at.to_date.advance(days: number).advance(days: -1)
    when 'week'
      start_at.to_date.advance(weeks: number).advance(days: -1)
    when 'month'
      start_at.to_date.advance(months: number).advance(days: -1)
    when 'year'
      start_at.to_date.advance(years: number).advance(days: -1)
    end
  end

  def in_week_out_compensatory_expiration?(date)
    week_out_compensatory_expiration_end_date >= date && week_out_compensatory_expiration_start_date <= date
  end

  def week_out_compensatory_expiration_term
    "#{week_out_compensatory_expiration_start_date.strftime("%Y/%m/%d")}#{I18n.t("ss.wave_dash")}#{week_out_compensatory_expiration_end_date.strftime("%Y/%m/%d")}"
  end

  def week_out_compensatory_notify_date
    return nil if site.week_out_compensatory_file_notify_day.blank?
    week_out_compensatory_expiration_end_date.advance(days: -1 * site.week_out_compensatory_file_notify_day)
  end

  def destroy_leave_compensatory
    [
      week_in_leave_file,
      week_out_leave_file,
      holiday_compensatory_leave_file
    ].each do |file|
      next if file.nil?
      file.destroy
    end
  end
end
