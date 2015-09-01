class Gws::Schedule::PlanRepeatBy
  include Mongoid::Document

  # 毎月の繰り返しの種類
  field :repeat_by, type: String

  # 毎月X日
  field :date, type: Integer

  # 毎月 第X,Y曜日
  field :ordinal, type: Integer
  # 日(0) - 土(6)
  field :week, type: Integer

  validates :repeat_by, inclusion: { in: ['date', 'week'] }

  validates :date, inclusion: { in: 1..31 }, if: :repeat_by_date?
  validates :ordinal, inclusion: { in: 0..4 }, if: :repeat_by_week?
  validates :week, inclusion: { in: 0..6 }, if: :repeat_by_week?

  embedded_in :plan_repeat, inverse_of: :repeat_by

  public
    def repeat_by_options
      [
        [I18n.t('schedule.options.repeat_by.date'), 'date'],
        [I18n.t('schedule.options.repeat_by.week'), 'week']
      ]
    end

    def repeat_by_date?
      repeat_by == 'date'
    end

    def repeat_by_week?
      repeat_by == 'week'
    end
end
