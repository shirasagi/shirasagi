module Gws::Addon::Affair::LeaveFile
  extend ActiveSupport::Concern
  extend SS::Addon
  include Compensatory

  included do
    attr_accessor :start_at_date, :start_at_hour, :start_at_minute,
      :end_at_date, :end_at_hour, :end_at_minute,
      :in_leave_dates, :leave_dates_in_query, :leave_minutes_in_query

    field :date, type: DateTime
    field :start_at, type: DateTime
    field :end_at, type: DateTime

    field :leave_type, type: String
    field :reason, type: String
    belongs_to :special_leave, class_name: "Gws::Affair::SpecialLeave"
    embeds_many :leave_dates, class_name: "Gws::Affair::LeaveDate"

    permit_params :start_at_date, :start_at_hour, :start_at_minute
    permit_params :end_at_date, :end_at_hour, :end_at_minute

    permit_params :leave_type, :reason, :special_leave
    permit_params :special_leave_id

    before_save :set_leave_dates, if: -> { in_leave_dates.present? }

    after_initialize :initialize_start_end
  end

  def start_at_hour_options
    (0..23).map { |h| [ I18n.t('gws/attendance.hour', count: h), h.to_s ] }
  end

  def start_at_minute_options
    (0..59).map { |m| [ I18n.t("gws/attendance.minute", count: m), m.to_s ] }
  end

  alias end_at_hour_options start_at_hour_options
  alias end_at_minute_options start_at_minute_options

  def leave_type_options
    I18n.t("gws/affair.options.leave_type").map { |k, v| [v, k] }
  end

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

  def validate_date
    self.start_at = parse_dhm(start_at_date, start_at_hour, start_at_minute)
    self.end_at = parse_dhm(end_at_date, end_at_hour, end_at_minute)
    return if start_at.blank? || end_at.blank?

    if start_at >= end_at
      errors.add :end_at, :greater_than, count: t(:start_at)
    end

    # 作成者ではなく申請者の勤務時間を確認する
    site = cur_site || self.site
    user = target_user
    return if site.blank? || user.blank?

    # 振替休暇（年休と特別休暇以外）は1日を超過できない
    if leave_type != "annual_leave" && leave_type != "paidleave" && end_at >= start_at.advance(days: 1)
      errors.add :base, :over_one_day
    end

    duty_calendar = user.effective_duty_calendar(site)
    changed_at = duty_calendar.affair_next_changed(start_at)
    self.date = changed_at.advance(days: -1).change(hour: 0, min: 0, sec: 0)

    # 実際に休日となった日時を保存
    validate_in_leave_dates

    # 年休の場合残り日数があるか
    validate_annual_leave
  end

  def validate_in_leave_dates
    duty_calendar = user.effective_duty_calendar(site)

    start_date = date
    end_date = end_at.change(hour: 0, min: 0, sec: 0)

    self.in_leave_dates = []
    (start_date..end_date).each do |date|
      next if duty_calendar.leave_day?(date)

      affair_start_at = duty_calendar.affair_start(date)
      affair_end_at = duty_calendar.affair_end(date)

      if start_date == date
        affair_start_at = start_at
      end
      if end_date == date
        affair_end_at = end_at
      end

      working_minute, = duty_calendar.working_minute(date, affair_start_at, affair_end_at)
      next if working_minute == 0
      minute = Gws::Affair::Utils.format_leave_minutes(site, working_minute)

      self.in_leave_dates << OpenStruct.new(
        date: date,
        start_at: affair_start_at,
        end_at: affair_end_at,
        working_minute: working_minute,
        minute: minute
      )
    end

    # 実際に休日となった日時がない
    #if in_leave_dates.map(&:minute).sum == 0
    #  errors.add :base, "有給開始〜終了が勤務時間外です。"
    #end
  end

  def validate_annual_leave
    return if leave_type != "annual_leave"

    start_date = date
    #end_date = end_at.change(hour: 0, min: 0, sec: 0)

    return if Gws::Affair::LeaveSetting.obtainable_annual_leave?(site, target_user, start_date, self)
    minutes = in_leave_dates.map(&:minute).sum
    errors.add :base, :not_enough_annual_leave_time, label: Gws::Affair::Utils.leave_minutes_label(minutes)
  end

  def set_leave_dates
    self.leave_dates.destroy_all
    self.leave_dates = in_leave_dates.map do |attr|
      self.leave_dates.new(attr)
    end
  end

  def start_end_term
    return if start_at.blank? || end_at.blank?
    start_time = "#{start_at.hour}:#{format('%02d', start_at.minute)}"
    end_time = "#{end_at.hour}:#{format('%02d', end_at.minute)}"
    if start_at_date == end_at_date
      "#{start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_time}"
    else
      "#{start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_at.strftime("%Y/%m/%d")} #{end_time}"
    end
  end

  def term_label
    name_label = target_user.try(:name)
    term_label = start_end_term
    return if name_label.blank? || term_label.blank?

    "#{name_label}の休暇申請（#{term_label}）"
  end
end
