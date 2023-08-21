class Gws::Schedule::RepeatPlan
  include SS::Document

  # 繰り返し daily, weekly, monthly, yearly
  field :repeat_type, type: String

  # 繰り返しの間隔
  field :interval, type: Integer

  # 開始-終了
  field :repeat_start, type: Date
  field :repeat_end, type: Date

  # 繰り返しの基準 date, wday / only monthly
  field :repeat_base, type: String, default: 'date'

  # 曜日 / only weekly
  field :wdays, type: Array, default: []

  validates :repeat_start, datetime: true
  validates :repeat_end, datetime: true

  before_validation do
    self.repeat_end = repeat_start + 1.month if repeat_start.present? && repeat_end.blank?
    self.wdays.reject! { |c| c.blank? }
  end

  validates :repeat_type, inclusion: { in: ['', 'daily', 'weekly', 'monthly', 'yearly'] }
  validates :interval, presence: true, if: -> { repeat_type.present? }
  validates :interval, inclusion: { in: 1..10 }, if: -> { interval.present? }
  validates :repeat_start, presence: true, if: -> { repeat_type.present? }
  validates :repeat_base, presence: true, if: -> { repeat_type == 'monthly' }

  validate :validate_plan_date, if: -> { repeat_start.present? && repeat_end.present? }
  validate :validate_plan_dates, if: -> { errors.empty? }

  def extract_plans(plan, site, user)
    save_plans(plan, site, user, plan_dates)
  end

  def plan_dates
    Gws::Schedule::DateEnumerator.new(
      repeat_type: repeat_type, repeat_start: repeat_start, repeat_end: repeat_end,
      interval: interval, wdays: wdays, repeat_base: repeat_base
    )
  end

  private

  def validate_plan_date
    errors.add :repeat_end, :greater_than, count: t(:repeat_start) if repeat_end < repeat_start
    if repeat_type != "yearly" && repeat_end > (repeat_start + 1.year)
      errors.add(:repeat_end, I18n.t("gws/schedule.errors.less_than_years", count: 1))
    end
  end

  def validate_plan_dates
    errors.add :base, I18n.t('gws/schedule.errors.empty_plan_days') if plan_dates.empty?
  end

  # 繰り返し予定を登録
  # @param [Plan]  base_plan 繰り返しの基準となる予定ドキュメント
  # @param [Array] dates     繰り返し予定を登録する日付の配列
  def save_plans(base_plan, site, user, dates)
    return if base_plan.edit_range == "one"

    time = [0, 0]
    diff = 0

    if base_plan.start_at
      time = [base_plan.start_at.hour, base_plan.start_at.min]
      diff = base_plan.end_at.to_i - base_plan.start_at.to_i if base_plan.end_at
    end

    attr = base_plan.attributes.dup
    attr.delete('_id')

    # Remove
    base_plan.class.where(repeat_plan_id: id, :_id.ne => base_plan.id).each do |plan|
      next if base_plan.edit_range == "later" && plan.start_at < base_plan.start_at

      plan.skip_gws_history
      plan.remove_repeat_reminder(base_plan) if plan.respond_to?(:remove_repeat_reminder)
      plan.destroy_without_repeat_plan
    end

    # Add
    saved = 0
    dates.each do |date|
      next if base_plan.edit_range == "later" && date < base_plan.start_at.to_date

      plan = (saved == 0) ? base_plan.class.find(base_plan.id) : base_plan.class.new.assign_attributes_safe(attr)
      plan.cur_site = site
      plan.cur_user = user

      if plan.allday?
        plan.start_on = Time.zone.local date.year, date.month, date.day, time[0], time[1], 0
        plan.end_on   = plan.start_on + diff.seconds
      else
        plan.start_at = Time.zone.local date.year, date.month, date.day, time[0], time[1], 0
        plan.end_at   = plan.start_at + diff.seconds
      end

      plan.skip_gws_history
      plan.set_repeat_reminder_conditions(base_plan) if plan.respond_to?(:set_repeat_reminder_conditions)
      plan.save
      saved += 1
    end
  end
end
