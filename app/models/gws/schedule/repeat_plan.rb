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
    save_plans plan, site, user, plan_dates
  end

  def plan_dates
    case repeat_type
    when 'daily'
      daily_dates
    when 'weekly'
      weekly_dates
    when 'monthly'
      monthly_dates
    when 'yearly'
      yearly_dates
    else
      []
    end
  end

  # 繰り返し予定を登録する日付の配列を返す（毎日）
  # @return [Array] 繰り返し予定を登録する日付の配列
  def daily_dates
    repeat_start.step(repeat_end, interval).to_a
  end

  # 繰り返し予定を登録する日付の配列を返す（毎週X曜日）
  # @return [Array] 繰り返し予定を登録する日付の配列
  def weekly_dates
    wdays = self.wdays.presence || [repeat_start.wday.to_s]
    dates = []

    (0..6).each do |i|
      if wdays.include?(i.to_s)
        date = get_date_next_specified_wday(repeat_start, i)
        dates << date if date <= repeat_end
      end
    end

    dates.each do |date|
      date += interval.week
      dates << date if date <= repeat_end
    end
    dates.sort
  end

  # 繰り返し予定を登録する日付の配列を返す（毎月）
  # @return [Array] 繰り返し予定を登録する日付の配列
  def monthly_dates
    repeat_base == 'date' ? monthly_dates_by_date : monthly_dates_by_week
  end

  # 繰り返し予定を登録する日付の配列を返す（毎年）
  # @return [Array] 繰り返し予定を登録する日付の配列
  def yearly_dates
    dates = []
    date = repeat_start
    while date <= repeat_end
      dates << date
      date += 1.year
    end
    dates
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

  # 基準日から見た次の指定曜日の日付を返す
  # @param  [Date]    base_date 基準日
  # @param  [Integer] wday      指定曜日(0-6 : 日-土)
  # @return [Date]              基準日から見た次の指定曜日の日付（基準日を含む）
  def get_date_next_specified_wday(base_date, wday)
    q = (wday - base_date.wday + 7) % 7
    base_date + q.day
  end

  # 繰り返し予定を登録する日付の配列を返す（毎月X日）
  # @return [Array] 繰り返し予定を登録する日付の配列
  def monthly_dates_by_date
    dates = []
    dates << repeat_start

    1.upto(1_024) do |i|
      date = (interval * i).months.since(repeat_start)
      break if date > repeat_end
      dates << date
    end
    dates
  end

  # 繰り返し予定を登録する日付の配列を返す（毎月第X曜日）
  # @return [Array] 繰り返し予定を登録する日付の配列
  def monthly_dates_by_week
    dates = []
    dates << repeat_start

    week = get_week_number_of_month(repeat_start)
    wday = repeat_start.wday

    dates.each do |dt|
      check_month = dt + interval.month
      check_date = get_date_by_nearest_ordinal_week(check_month.year, check_month.month, week, wday)
      dates << check_date if check_date <= repeat_end
    end
    dates
  end

  # 指定された日付がその月の第何週かを返す
  # @param  [Date]    base_date 基準日
  # @return [Integer]           第何週(1-5)
  def get_week_number_of_month(base_date)
    repeat_start = Date.new(base_date.year, base_date.month, 1)
    week_number = 0

    repeat_start.upto(base_date.to_date).each do |dt|
      week_number += 1 if dt.wday == base_date.wday
    end

    week_number
  end

  # 条件に合致する日付を返す
  # @param  [Integer] year    年
  # @param  [Integer] month   月
  # @param  [Integer] week    第何週
  # @param  [Integer] wday    曜日
  # @return [Date]            条件に合致する日付
  # @return [nil]             条件が不正な場合はnilが返る
  def get_date_by_ordinal_week(year, month, week, wday)
    repeat_start = Date.new(year, month, 1)
    repeat_end = repeat_start.end_of_month

    diff_wday = wday - repeat_start.wday
    diff_wday += 7 if diff_wday < 0

    repeat_start += diff_wday
    repeat_start += (week - 1) * 7

    repeat_start <= repeat_end ? repeat_start : nil
  end

  # 条件に近い日付を返す
  # @param  [Integer] year    年
  # @param  [Integer] month   月
  # @param  [Integer] week    第何週
  # @param  [Integer] wday    曜日
  # @return [Date]            条件に合致する日付
  #                             条件が不正な場合は近い日が返る
  #                             例えば 4 月に第 5 月曜日が存在しなかった場合、第 4 月曜日を返す。
  def get_date_by_nearest_ordinal_week(year, month, week, wday)
    while week > 0
      ret = get_date_by_ordinal_week(year, month, week, wday)
      break if ret.present?
      week -= 1
    end
    ret
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
      plan.save
      saved += 1
    end
  end
end
