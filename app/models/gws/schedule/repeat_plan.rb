class Gws::Schedule::RepeatPlan
  include SS::Document

  # 繰り返し daily, weekly, monthly
  field :repeat_type, type: String

  # 繰り返しの間隔
  field :interval, type: Integer

  # 開始-終了
  field :start_date, type: Date
  field :end_date, type: Date

  # 繰り返しの基準 date, wday / only monthly
  field :repeat_base, type: String, default: 'date'

  # 曜日 / only weekly
  field :wdays, type: Array, default: []

  before_validation do
    self.end_date = Date.new(start_date.year, 12, 31) if start_date.present? && end_date.blank?
    self.wdays.reject! { |c| c.blank? }
  end

  validates :repeat_type, inclusion: { in: ['', 'daily', 'weekly', 'monthly'] }
  validates :interval, presence: true, if: -> { repeat_type.present? }
  validates :interval, inclusion: { in: 1..10 }, if: -> { interval.present? }
  validates :start_date, presence: true, if: -> { repeat_type.present? }
  validates :repeat_base, presence: true, if: -> { repeat_type == 'monthly' }
  #validates :wdays, presence: true, if: -> { repeat_type == 'weekly' }

  validate :validate_plan_date, if: -> { start_date.present? && end_date.present? }
  validate :validate_plan_dates, if: -> { errors.size == 0 }

  public
    def validate_plan_date
      errors.add :end_date, :greater_than, count: t(:start_date) if end_date <= start_date
      errors.add(:end_date, I18n.t("gws_schedule.errors.less_than_years", count: 1)) if end_date > (start_date + 1.year)
    end

    def validate_plan_dates
      errors.add :base, I18n.t('gws_schedule.errors.empty_plan_days') if plan_dates.size == 0
    end

    def extract_plans(plan)
      save_plans plan, plan_dates
    end

    def plan_dates
      case repeat_type
      when 'daily'
        daily_dates
      when 'weekly'
        weekly_dates
      when 'monthly'
        monthly_dates
      else
        []
      end
    end

    # 繰り返し予定を登録する日付の配列を返す（毎日）
    # @return [Array] 繰り返し予定を登録する日付の配列
    def daily_dates
      start_date.step(end_date, interval).to_a
    end

    # 繰り返し予定を登録する日付の配列を返す（毎週X曜日）
    # @return [Array] 繰り返し予定を登録する日付の配列
    def weekly_dates
      wdays = self.wdays.presence || [start_date.wday.to_s]
      dates = []

      (0..6).each do |i|
        if wdays.include?(i.to_s)
          date = get_date_next_specified_wday(start_date, i)
          dates << date if date <= end_date
        end
      end

      dates.each do |date|
        date = date + interval.week
        dates << date if date <= end_date
      end
      dates.sort
    end

    # 繰り返し予定を登録する日付の配列を返す（毎月）
    # @return [Array] 繰り返し予定を登録する日付の配列
    def monthly_dates
      repeat_base == 'date' ? monthly_dates_by_date : monthly_dates_by_week
    end

  private
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
      dates << start_date

      dates.each do |date|
        date = date + interval.month
        dates << date if date <= end_date
      end
      dates
    end

    # 繰り返し予定を登録する日付の配列を返す（毎月第X曜日）
    # @return [Array] 繰り返し予定を登録する日付の配列
    def monthly_dates_by_week
      dates = []
      dates << start_date

      week = get_week_number_of_month(start_date)
      wday = start_date.wday

      dates.each do |dt|
        check_month = dt + interval.month
        check_date = get_date_by_ordinal_week(check_month.year, check_month.month, week, wday)
        dates << check_date if check_date <= end_date
      end
      dates
    end

    # 指定された日付がその月の第何週かを返す
    # @param  [Date]    base_date 基準日
    # @return [Integer]           第何週(1-5)
    def get_week_number_of_month(base_date)
      start_date = Date.new(base_date.year, base_date.month, 1)
      week_number = 0

      start_date.upto(base_date.to_date).each do |dt|
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
      start_date = Date.new(year, month, 1)
      end_date = start_date + 1.month - 1.day
      return_date = nil

      start_date.upto(end_date).each do |dt|
        if get_week_number_of_month(dt) == week && dt.wday == wday
          return_date = Date.parse(dt.to_s)
          break
        end
      end
      return_date
    end

    # 繰り返し予定を登録
    # @param [Plan]  base_plan 繰り返しの基準となる予定ドキュメント
    # @param [Array] dates     繰り返し予定を登録する日付の配列
    def save_plans(base_plan, dates)
      sdt = base_plan.start_at
      edt = base_plan.end_at

      attr = base_plan.attributes.dup
      attr.delete('_id')

      #TODO: 最適化
      base_plan.class.where(repeat_plan_id: id, :_id.ne => base_plan.id).destroy

      dates.each_with_index do |date, idx|
        if idx == 0
          plan = base_plan.class.find(base_plan.id)
        else
          plan = base_plan.class.new(attr)
        end

        plan.start_at = DateTime.new date.year, date.month, date.day, sdt.hour, sdt.min, sdt.sec
        plan.end_at   = DateTime.new date.year, date.month, date.day, edt.hour, edt.min, edt.sec
        plan.end_at   = plan.start_at if base_plan.allday?
        plan.save
      end
    end
end
