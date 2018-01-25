class Gws::Attendance::TimeEdit
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :cur_site, :cur_user
  attr_accessor :in_hour, :in_minute, :in_reason

  permit_params :in_hour, :in_minute, :in_reason

  validates :in_hour, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 24, allow_blank: true }
  validates :in_minute, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 60, allow_blank: true }
  validates :in_reason, presence: true, length: { maximum: 80 }

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end

  def calc_time(date)
    if in_hour.blank? || in_minute.blank?
      return nil
    else
      date.change(hour: Integer(in_hour), min: Integer(in_minute))
    end
  end
end
