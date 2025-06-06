class Gws::Affair2::Overtime::Record
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site

  attr_accessor :in_start_hour, :in_start_minute,
    :in_close_hour, :in_close_minute,
    :in_break_start_hour, :in_break_start_minute,
    :in_break_close_hour, :in_break_close_minute,
    :duty_setting

  permit_params :in_start_hour, :in_start_minute,
    :in_close_hour, :in_close_minute,
    :in_break_start_hour, :in_break_start_minute,
    :in_break_close_hour, :in_break_close_minute

  belongs_to :file, class_name: "Object", polymorphic: true
  field :date, type: DateTime
  field :start_at, type: DateTime
  field :close_at, type: DateTime
  field :break_start_at, type: DateTime
  field :break_close_at, type: DateTime

  ## 結果
  field :state, type: String, default: "request"
  field :entered_at, type: DateTime #結果が入力されたら通知する
  field :confirmed_at, type: DateTime #確認済みになったら通知する
  field :day_minutes, type: Integer
  field :night_minutes, type: Integer
  field :day_break_minutes, type: Integer
  field :night_break_minutes, type: Integer

  ## 振替
  field :expense, type: String
  field :compens_date, type: DateTime

  before_validation :set_start_close
  validates :date, presence: true
  validate :validate_start_close
  validate :validate_state
  before_save :set_minutes

  def hour_options
    self.site ||= @cur_site
    hour_start = site.affair2_night_time_close_hour % 24
    hour_close = hour_start + 24
    hour_start.upto(hour_close).map { |h| [ I18n.t('gws/attendance.hour', count: h), h ] }
  end

  def minute_options
    60.times.to_a.map { |m| [ I18n.t('gws/attendance.minute', count: m), m ] }
  end

  # state: request 申請
  # state: order 命令
  # state: order, first_entered: 結果入力済み
  # state: order, first_confirmed: 結果確認済み
  def state_options
    %w(request order).map { |k| [I18n.t("gws/affair2.options.record_state.#{k}"), k] }
  end

  def entered?
    entered_at.present?
  end

  def confirmed?
    confirmed_at.present?
  end

  def holiday?
    compens? || settle?
  end

  def compens?
    expense == "compens"
  end

  def settle?
    expense == "settle"
  end

  def load_in_accessor
    if start_at && close_at && break_start_at && break_close_at
      load_in_accessor_from_field
    elsif file
      load_in_accessor_from_file
    end
  end

  def load_in_accessor_from_field
    self.in_start_hour = start_at.hour
    self.in_start_minute = start_at.min
    self.in_close_hour = (start_at.to_date == close_at.to_date) ? close_at.hour : close_at.hour + 24
    self.in_close_minute = close_at.min

    self.in_break_start_hour = (start_at.to_date == break_start_at.to_date) ? break_start_at.hour : break_start_at.hour + 24
    self.in_break_start_minute = break_start_at.min
    self.in_break_close_hour = (start_at.to_date == break_close_at.to_date) ? break_close_at.hour : break_close_at.hour + 24
    self.in_break_close_minute = break_close_at.min
  end

  def load_in_accessor_from_file
    self.in_start_hour = file.start_at.hour
    self.in_start_minute = file.start_at.min
    self.in_close_hour = (file.start_at.to_date == file.close_at.to_date) ? file.close_at.hour : file.close_at.hour + 24
    self.in_close_minute = file.close_at.min

    self.in_break_start_hour = file.start_at.hour
    self.in_break_start_minute = file.start_at.min
    self.in_break_close_hour = file.start_at.hour
    self.in_break_close_minute = file.start_at.min
  end

  alias in_start_hour_options hour_options
  alias in_start_minute_options minute_options
  alias in_close_hour_options hour_options
  alias in_close_minute_options minute_options
  alias in_break_start_hour_options hour_options
  alias in_break_start_minute_options minute_options
  alias in_break_close_hour_options hour_options
  alias in_break_close_minute_options minute_options

  def work_minutes
    return if day_minutes.nil? || night_minutes.nil?
    day_minutes + night_minutes
  end

  def break_minutes
    return if day_break_minutes.nil? || night_break_minutes.nil?
    day_break_minutes + night_break_minutes
  end

  def set_start_close
    return if date.nil?

    if in_start_hour && in_start_minute
      self.start_at = date.advance(hours: in_start_hour.to_i, minutes: in_start_minute.to_i, sec: 0) rescue nil
    end
    if in_close_hour && in_close_minute
      self.close_at = date.advance(hours: in_close_hour.to_i, minutes: in_close_minute.to_i, sec: 0) rescue nil
    end
    if in_break_start_hour && in_break_start_minute
      self.break_start_at = date.advance(hours: in_break_start_hour.to_i, minutes: in_break_start_minute.to_i, sec: 0) rescue nil
    end
    if in_break_close_hour && in_break_close_minute
      self.break_close_at = date.advance(hours: in_break_close_hour.to_i, minutes: in_break_close_minute.to_i, sec: 0) rescue nil
    end
  end

  def night_time_start_at(date)
    site.affair2_night_time_start_at(date)
  end

  def night_time_close_at(date)
    site.affair2_night_time_close_at(date)
  end

  def validate_start_close
    if start_at && close_at && start_at >= close_at
      errors.add :close_at, :after_than, time: t(:start_at)
    end
    if break_start_at && break_close_at && break_start_at > break_close_at
      errors.add :break_close_at, :after_than, time: t(:break_start_at)
    end
  end

  def validate_state
    if entered? || confirmed?
      errors.add :start_at, :blank if start_at.nil?
      errors.add :close_at, :blank if close_at.nil?
      errors.add :break_start_at, :blank if break_start_at.nil?
      errors.add :break_close_at, :blank if break_close_at.nil?
    end
  end

  def set_minutes
    self.site ||= @cur_site
    self.day_minutes = nil
    self.night_minutes = nil
    self.day_break_minutes = nil
    self.night_break_minutes = nil

    return if file.nil?
    return if !entered?

    record = file.time_card_record
    return if record.nil?

    if record.regular_workday?
      # 勤務日の場合は 所定終業 から 深夜時間外終了 まで
      day_range = (record.regular_close..night_time_start_at(date))
    else
      # 休業日の場合は 前日の深夜時間外終了 から 深夜時間外終了 まで
      day_range = (night_time_close_at(date.advance(days: -1))..night_time_start_at(date))
    end
    night_range = (night_time_start_at(date)..night_time_close_at(date))

    sub_ranges = []
    sub_ranges << (start_at..close_at)
    sub_ranges << (break_start_at..break_close_at)

    day_minutes = ::Gws::Affair2::Utils.time_range_minutes(day_range, *sub_ranges)
    night_minutes = ::Gws::Affair2::Utils.time_range_minutes(night_range, *sub_ranges)

    self.day_minutes = day_minutes[1]
    self.night_minutes = night_minutes[1]
    self.day_break_minutes = day_minutes[2]
    self.night_break_minutes = night_minutes[2]
  end
end
