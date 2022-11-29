class Gws::Affair::OvertimeResult
  include SS::Document

  attr_accessor :start_at_date, :start_at_hour, :start_at_minute,
    :end_at_date, :end_at_hour, :end_at_minute,
    :break1_start_at_date, :break1_start_at_hour, :break1_start_at_minute,
    :break1_end_at_date, :break1_end_at_hour, :break1_end_at_minute,
    :break2_start_at_date, :break2_start_at_hour, :break2_start_at_minute,
    :break2_end_at_date, :break2_end_at_hour, :break2_end_at_minute

  embedded_in :file, class_name: "Gws::Addon::Affair::OvertimeFile"
  field :date, type: DateTime
  field :start_at, type: DateTime
  field :end_at, type: DateTime

  field :break1_start_at, type: DateTime
  field :break1_end_at, type: DateTime
  field :break2_start_at, type: DateTime
  field :break2_end_at, type: DateTime
  field :break_time_minute, type: Integer, default: 0

  validates :date, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true

  after_initialize do
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
    if break1_start_at
      self.break1_start_at_date = break1_start_at.strftime("%Y/%m/%d")
      self.break1_start_at_hour = break1_start_at.hour
      self.break1_start_at_minute = break1_start_at.minute
    end
    if break1_end_at
      self.break1_end_at_date = break1_end_at.strftime("%Y/%m/%d")
      self.break1_end_at_hour = break1_end_at.hour
      self.break1_end_at_minute = break1_end_at.minute
    end
    if break2_start_at
      self.break2_start_at_date = break2_start_at.strftime("%Y/%m/%d")
      self.break2_start_at_hour = break2_start_at.hour
      self.break2_start_at_minute = break2_start_at.minute
    end
    if break2_end_at
      self.break2_end_at_date = break2_end_at.strftime("%Y/%m/%d")
      self.break2_end_at_hour = break2_end_at.hour
      self.break2_end_at_minute = break2_end_at.minute
    end
  end
end
