class Gws::Affair2::Attendance::Record
  extend SS::Translation
  include SS::Document

  embedded_in :time_card, class_name: 'Gws::Affair2::Attendance::TimeCard'

  cattr_accessor(:punchable_field_names)

  self.punchable_field_names = %w(enter leave)

  attr_accessor :etc_travel_cost, :location_id

  delegate :time_to_min, :min_to_time, to: Gws::Affair2::Utils

  ##
  field :date, type: DateTime
  field :enter, type: DateTime # 出勤打刻
  field :leave, type: DateTime # 退勤打刻
  field :break_minutes, type: Integer # 休憩時間(分)
  field :memo, type: String # 備考
  ##
  field :regular_start, type: DateTime # 所定開始時刻
  field :regular_close, type: DateTime # 所定終了時刻
  field :regular_work_minutes,  type: Integer # 所定時間
  field :regular_break_minutes, type: Integer # 所定休憩時間
  field :regular_holiday, type: String # 所定休日
  ##
  field :work_minutes, type: Integer # 執務時間(分)
  field :over_minutes, type: Integer # 時間外時間(分)

  self.punchable_field_names = self.punchable_field_names.freeze

  validates :date, presence: true
  validate :validate_regular

  before_save :set_regular_work_minutes
  before_save :set_break_minutes
  before_save :set_work_minutes
  before_save :set_over_minutes

  # 所定時間が入力され準備完了か？
  def regular_open?
    return true if regular_holiday?
    return (regular_start && regular_close && regular_break_minutes && regular_work_minutes) if regular_workday?
    false
  end

  # 所定時間が入力されており、出勤/退勤が入力されているか？
  def entered?
    regular_open? && enter && leave
  end

  def find_latest_history(field_name)
    criteria = time_card.histories.where(date: date.in_time_zone('UTC'), field_name: field_name)
    criteria.order_by(created: -1).first
  end

  def work_time
    return nil if work_minutes.nil?
    min_to_time(date, min: work_minutes)
  end

  def over_time
    return nil if over_minutes.nil?
    min_to_time(date, min: over_minutes)
  end

  def regular_holiday_options
    I18n.t("gws/affair2.options.regular_holiday").map { |k, v| [v, k] }
  end

  def regular_workday?
    !regular_holiday?
  end

  def regular_holiday?
    regular_holiday == "holiday"
  end

  def effective_enter
    return if !entered?
    return if regular_holiday?
    (enter > regular_start) ? enter : regular_start
  end

  def effective_leave
    return if !entered?
    return if regular_holiday?
    (leave < regular_close) ? leave : regular_close
  end

  private

  def validate_regular
    if regular_holiday?
      self.regular_start = nil
      self.regular_close = nil
      self.regular_break_minutes = nil
    end
    if regular_start && regular_close && regular_start >= regular_close
      errors.add :regular_close, :greater_than, count: t(:regular_start)
    end
  end

  def set_regular_work_minutes
    return if regular_work_minutes
    if regular_start && regular_close && regular_break_minutes
      minutes = time_to_min(regular_close) - time_to_min(regular_start) - regular_break_minutes
      minutes > 0 ? minutes : 0
      self.regular_work_minutes = minutes
    end
  end

  def set_break_minutes
    return if break_minutes
    return if !regular_open?

    # 休業日の場合は時間外の休憩時間を入力する
    return if regular_holiday?

    if enter && leave
      diff = time_to_min(effective_leave, date: date) - time_to_min(effective_enter, date: date)

      self.break_minutes = 0
      # 6時間以上なら休憩時間を入れる
      self.break_minutes = regular_break_minutes if diff >= (6 * 60)
    end
  end

  def set_work_minutes
    return if !entered?

    if regular_workday?
      self.work_minutes = time_to_min(effective_leave, date: date) - time_to_min(effective_enter, date: date) - break_minutes.to_i
      self.work_minutes = 0 if work_minutes < 0
    else
      # 休業日の場合は残業になるのでnil
      self.work_minutes = nil
    end
  end

  def set_over_minutes
    return if !entered?

    if regular_workday?
      effective_close = regular_close > enter ? regular_close : enter
      self.over_minutes = time_to_min(leave, date: date) - time_to_min(effective_close, date: date)
    else
      self.over_minutes = time_to_min(leave, date: date) - time_to_min(enter, date: date) - break_minutes.to_i
    end
    self.over_minutes = 0 if over_minutes < 0
  end
end
