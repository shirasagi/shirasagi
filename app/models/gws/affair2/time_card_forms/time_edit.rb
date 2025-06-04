class Gws::Affair2::TimeCardForms::TimeEdit
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :record, :field, :required_reason
  attr_accessor :hour, :minute, :reason

  permit_params :hour, :minute, :reason

  validate :numericalize
  validates :hour, numericality: { only_integer: true, allow_blank: true }
  validates :minute, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 60, allow_blank: true }
  validates :reason, presence: true, if: -> { required_reason }

  def initialize(record, field, required_reason: true)
    @record = record
    @field = field
    @required_reason = required_reason

    time = record.send(field)
    if time
      @hour = (time.day - record.date.day) * 24 + time.hour
      @minute = time.min
    end
  end

  def numericalize
    @hour = hour.present? ? hour.to_i : nil
    @minute = minute.present? ? minute.to_i : nil
  end

  def save
    return false if invalid?

    if hour && minute
      d = hour / 24
      h = hour % 24
      time = @record.date.advance(days: d).change(hour: h, min: minute)
    else
      time = nil
    end
    @record.send("#{field}=", time)
    if !@record.save
      SS::Model.copy_errors(@record, self)
      return false
    end
    true
  end

  private

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end
end
