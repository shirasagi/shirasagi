class Gws::Schedule::PlanRepeat
  include SS::Document
  include Gws::Schedule::Planable

  after_create :entry_plans

  field :kind, type: String
  field :repeat_start_at, type: DateTime
  field :repeat_end_at, type: DateTime

  embeds_one :repeat_on, class_name: 'Gws::Schedule::PlanRepeatOn'
  embeds_one :repeat_by, class_name: 'Gws::Schedule::PlanRepeatBy'

  has_many :plan, class_name: 'Gws::Schedule::Plan', dependent: :destroy

  validate :repeat_end_at_within_one_year

  public
    # 繰り返しの種類を指定する
    def kind_options
      [
        [I18n.t('schedule.options.kind.daily'), 'daily'],
        [I18n.t('schedule.options.kind.weekly'), 'weekly'],
        [I18n.t('schedule.options.kind.monthly'), 'monthly']
      ]
    end

    # 繰り返し予定の登録
    def entry_plans
      case kind
      when 'daily'
        entry_plans_daily
      when 'weekly'
        entry_plans_weekly
      when 'monthly'
        entry_plans_monthly
      end
    end

    # 繰り返し予定の登録（毎日）
    def entry_plans_daily
      entry_schedule_plan(repeat_start_at.upto(repeat_end_at))
    end

    # 繰り返し予定の登録（毎週）
    def entry_plans_weekly
      entry_schedule_plan(get_entry_dates_weekly)
    end

    # 繰り返し予定の登録（毎月）
    def entry_plans_monthly
      case repeat_by.repeat_by
      when 'date'
        entry_schedule_plan(get_entry_dates_monthly_by_date)
      when 'week'
        entry_schedule_plan(get_entry_dates_monthly_by_week)
      end
    end

    # 基準日から見た次の指定曜日の日付を返す
    # @param  [Date]    base_date 基準日
    # @param  [Integer] wday      指定曜日(0-6 : 日-土)
    # @return [Date]              基準日から見た次の指定曜日の日付（基準日を含む）
    def get_date_next_specified_wday(base_date = Time.zone.today, wday)
      q = (wday - base_date.wday + 7) % 7
      base_date + q.day
    end

    # 繰り返し予定を登録する日付の配列を返す（毎週X曜日）
    # @return [Array] 繰り返し予定を登録する日付の配列
    def get_entry_dates_weekly
      entry_dates = []
      start_date = repeat_start_at

      entry_dates << get_date_next_specified_wday(start_date, 0) if repeat_on.sunday
      entry_dates << get_date_next_specified_wday(start_date, 1) if repeat_on.monday
      entry_dates << get_date_next_specified_wday(start_date, 2) if repeat_on.tuesday
      entry_dates << get_date_next_specified_wday(start_date, 3) if repeat_on.wednesday
      entry_dates << get_date_next_specified_wday(start_date, 4) if repeat_on.thursday
      entry_dates << get_date_next_specified_wday(start_date, 5) if repeat_on.friday
      entry_dates << get_date_next_specified_wday(start_date, 6) if repeat_on.saturday

      entry_dates.each do |dt|
        entry_dates << dt + 1.week if (dt + 1.week) <= repeat_end_at
      end
      entry_dates.sort
    end

    # 繰り返し予定を登録する日付の配列を返す（毎月X日）
    # @return [Array] 繰り返し予定を登録する日付の配列
    def get_entry_dates_monthly_by_date
      entry_dates = []
      entry_dates << repeat_start_at

      entry_dates.each do |dt|
        entry_dates << dt + 1.month if (dt + 1.month) <= repeat_end_at
      end
      entry_dates
    end

    # 繰り返し予定を登録する日付の配列を返す（毎月第X,Y曜日）
    # @return [Array] 繰り返し予定を登録する日付の配列
    def get_entry_dates_monthly_by_week
      entry_dates = []
      entry_dates << repeat_start_at

      entry_dates.each do |dt|
        check_month = dt + 1.month
        check_date = get_date_by_ordinal_week(check_month.year, check_month.month, repeat_by.ordinal, repeat_by.week)
        entry_dates << check_date if check_date <= repeat_end_at
      end
      entry_dates
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
    # @param  [Integer] ordinal 第何週
    # @param  [Integer] week    曜日
    # @return [Date]            条件に合致する日付
    # @return [nil]             条件が不正な場合はnilが返る
    def get_date_by_ordinal_week(year, month, ordinal, week)
      start_date = Date.new(year, month, 1)
      end_date = start_date + 1.month - 1.day
      return_date = nil

      start_date.upto(end_date).each do |dt|
        if get_week_number_of_month(dt) == ordinal && dt.wday == week
          return_date = Time.zone.parse(dt.to_s)
          break
        end
      end
      return_date
    end

    # 繰り返し予定を登録
    # @param [Array] 繰り返し予定を登録する日付の配列
    def entry_schedule_plan(entry_dates)
      #TODO: 引数の確認
      entry_dates.each do |e|
        # 日付をまたいでいるかもしれないので、終了日は計算する
        end_day = e.day + (end_at.day - start_at.day)

        Gws::Schedule::Plan.create(
          name: name,
          text: text,
          start_at: Time.zone.local(e.year, e.month, e.day, start_at.hour, start_at.minute),
          end_at: Time.zone.local(e.year, e.month, end_day, end_at.hour, end_at.minute),
          allday: allday,
          repeat: self
        )
      end
    end

    # 基準日以降の予定を削除
    # @param [Date] base_date 基準日
    def delete_schedule_plan(base_date)
      plan.where(:start_at.gte => base_date).each do |sp|
        sp.destroy
      end
    end

  private
    # 繰り返し予定の登録期間は1年を超えない
    def repeat_end_at_within_one_year
      if repeat_end_at > (repeat_start_at + 1.year)
        errors.add(:repeat_end_at, ': specify the period within one year')
      end
    end
end
