class Gws::Affair::Attendance::TimeEdit
  include Gws::Model::Attendance::TimeEdit

  attr_accessor :in_day
  attr_accessor :in_reason_type

  permit_params :in_day
  permit_params :in_reason_type

  validates :in_day, inclusion: { in: %w(today tomorrow), allow_blank: true }
  validates :in_reason_type, inclusion: { in: %w(today tomorrow mistake trip exemption other) }
  validates :in_reason, length: { maximum: 80 }

  def calc_time(date)
    if in_hour.blank? || in_minute.blank?
      return nil
    elsif in_day == "tomorrow"
      date.tomorrow.beginning_of_day + Integer(in_hour).hours + Integer(in_minute).minutes
    else
      date.beginning_of_day + Integer(in_hour).hours + Integer(in_minute).minutes
    end
  end
end
