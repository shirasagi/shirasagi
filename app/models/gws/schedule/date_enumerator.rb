class Gws::Schedule::DateEnumerator
  include Enumerable
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor :repeat_type, :repeat_start, :repeat_end, :interval, :wdays, :repeat_base

  before_validation :normalize_wdays

  validates :repeat_type, inclusion: { in: %w(daily weekly monthly yearly) }
  validates :repeat_start, presence: true
  validates :repeat_end, presence: true
  validates :interval, presence: true, inclusion: { in: 1..10 }
  validates :repeat_base, inclusion: { in: %w(date wday), allow_blank: true }
  validates :repeat_base, presence: true, if: -> { repeat_type == 'monthly' }

  def each(&block)
    return if invalid?

    case repeat_type
    when 'daily'
      each_daily_dates(&block)
    when 'weekly'
      each_weekly_dates(&block)
    when 'monthly'
      if repeat_base_date?
        each_monthly_dates_by_date(&block)
      else
        each_monthly_dates_by_week(&block)
      end
    when 'yearly'
      each_yearly_dates(&block)
    end
  end

  def empty?
    first.nil?
  end

  class << self
    # 指定された日付がその月の第何週かを返す
    # @param  [Date]    base_date 基準日
    # @return [Integer]           第何週(1-5)
    def get_week_number_of_month(base_date)
      days = base_date.day
      week_number = days / 7
      week_number += 1 if (days % 7) != 0
      week_number
    end

    # 条件に近い日付を返す
    # @param  [Date]    base_date 基準日
    # @param  [Integer] week    第何週(1-5)
    # @param  [Integer] wday    曜日(0-6)
    # @return [Date]            条件に合致する日付
    #                             条件が不正な場合は近い日が返る
    #                             例えば 4 月に第 5 月曜日が存在しなかった場合、第 4 月曜日を返す。
    def get_date_by_nearest_ordinal_week(base_date, week, wday)
      ret = base_date.beginning_of_month + ((week - 1) * 7).days
      offset = wday - ret.wday
      offset += 7 if offset < 0
      ret += offset.days
      if ret > base_date.end_of_month
        ret -= 7.days while ret > base_date.end_of_month
      end
      ret
    end
  end

  private

  def normalize_wdays
    if self.wdays.present?
      self.wdays.reject!(&:blank?)
      self.wdays.map!(&:to_i)
    end
  end

  def each_dates_with_next_func(next_func, &block)
    yield repeat_start
    s = next_func.call(repeat_start)
    while s <= repeat_end
      yield s
      s = next_func.call(s)
    end
  end

  # 繰り返し予定を登録する日付を列挙する（毎日）
  def each_daily_dates(&block)
    next_func = proc do |date|
      date + interval.days
    end
    each_dates_with_next_func(next_func, &block)
  end

  # 繰り返し予定を登録する日付を列挙する（毎年）
  def each_yearly_dates(&block)
    next_func = proc do |date|
      date + interval.years
    end
    each_dates_with_next_func(next_func, &block)
  end

  # 繰り返し予定を登録する日付を列挙する（毎週X曜日）
  def each_weekly_dates(&block)
    wdays = self.wdays.presence || [repeat_start.wday]

    s = repeat_start
    while s <= repeat_end
      (0..6).each do |i|
        target = s + i.days
        yield target if wdays.include?(target.wday) && target <= repeat_end
      end

      s += interval.weeks
    end
  end

  def repeat_base_date?
    !repeat_base_wday?
  end

  def repeat_base_wday?
    repeat_base == 'wday'
  end

  # 繰り返し予定を登録する日付の配列を返す（毎月X日）
  # @return [Array] 繰り返し予定を登録する日付の配列
  def each_monthly_dates_by_date(&block)
    0.upto(1_024) do |i|
      date = repeat_start + (interval * i).months
      break if date > repeat_end
      yield date
    end
  end

  # 繰り返し予定を登録する日付の配列を返す（毎月第X曜日）
  # @return [Array] 繰り返し予定を登録する日付の配列
  def each_monthly_dates_by_week(&block)
    week = self.class.get_week_number_of_month(repeat_start)
    wday = repeat_start.wday

    check_date = self.class.get_date_by_nearest_ordinal_week(repeat_start, week, wday)
    return if check_date > repeat_end

    yield check_date

    check_month = repeat_start + interval.months
    loop do
      check_date = self.class.get_date_by_nearest_ordinal_week(check_month, week, wday)
      break if check_date > repeat_end
      yield check_date
      check_month += interval.months
    end
  end
end
