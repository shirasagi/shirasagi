module Gws::Addon::Affair::OvertimeFile
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Affair::OvertimeFile::Compensatory

  included do
    attr_accessor :start_at_date, :start_at_hour, :start_at_minute
    attr_accessor :end_at_date, :end_at_hour, :end_at_minute

    field :overtime_name, type: String
    field :date, type: DateTime
    field :start_at, type: DateTime
    field :end_at, type: DateTime
    field :remark, type: String

    permit_params :overtime_name
    permit_params :start_at_date, :start_at_hour, :start_at_minute
    permit_params :end_at_date, :end_at_hour, :end_at_minute
    permit_params :remark

    before_validation :validate_date

    before_validation :validate_compensatory_minute
    before_validation :validate_week_in_compensatory_minute
    before_validation :validate_week_out_compensatory_minute
    before_validation :validate_holiday_compensatory_minute

    validates :overtime_name, presence: true, length: { maximum: 80 }
    validates :start_at, presence: true, datetime: true
    validates :end_at, presence: true, datetime: true

    before_save :set_name_by_term

    after_destroy :destroy_leave_compensatory
  end

  def start_at_hour_options
    (0..23).map { |h| [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ] }
  end

  def start_at_minute_options
    # (0..59).select { |m| m % 5 == 0 }.map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
    0.step(59, 5).map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
  end

  def end_at_hour_options
    (0..23).map { |h| [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ] }
  end

  def end_at_minute_options
    # (0..59).select { |m| m % 5 == 0 }.map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
    0.step(59, 5).map { |m| [ "#{m}#{I18n.t('datetime.prompts.minute')}", m.to_s ] }
  end

  def validate_date
    return if start_at_date.blank? || start_at_hour.blank? || start_at_minute.blank?
    return if end_at_date.blank? || end_at_hour.blank? || end_at_minute.blank?

    site = self.site || cur_site

    # 作成者ではなく申請者の勤務時間を確認する
    user = target_user

    return if site.blank?
    return if user.blank?

    self.start_at = Time.zone.parse("#{start_at_date} #{start_at_hour}:#{start_at_minute}")
    self.end_at = Time.zone.parse("#{end_at_date} #{end_at_hour}:#{end_at_minute}")

    if start_at >= end_at
      errors.add :end_at, :greater_than, count: t(:start_at)
    end

    duty_calendar = user.effective_duty_calendar(site)

    changed_at = duty_calendar.affair_next_changed(start_at)
    self.date = changed_at.advance(days: -1).change(hour: 0, min: 0, sec: 0)

    #if end_at > changed_at
    #  errors.add :base, :over_change_hour
    #end
    if end_at >= start_at.advance(days: 1)
      errors.add :base, :over_one_day
    end

    return if duty_calendar.leave_day?(date)

    affair_start = duty_calendar.affair_start(start_at)
    affair_end = duty_calendar.affair_end(start_at)
    in_affair_at1 = end_at > affair_start && start_at < affair_end

    affair_start = duty_calendar.affair_start(end_at)
    affair_end = duty_calendar.affair_end(end_at)
    in_affair_at2 = end_at > affair_start && start_at < affair_end

    if in_affair_at1 || in_affair_at2
      errors.add :base, :in_duty_hour
    end
  end

  def start_end_term
    start_time = "#{start_at.hour}:#{format('%02d', start_at.minute)}"
    end_time = "#{end_at.hour}:#{format('%02d', end_at.minute)}"
    if start_at_date == end_at_date
      "#{start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_time}"
    else
      "#{start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_at.strftime("%Y/%m/%d")} #{end_time}"
    end
  end

  def term_label
    "#{overtime_name}（#{start_end_term}）"
  end

  private

  def set_name_by_term
    return if name.present?
    self.name = term_label
  end
end
