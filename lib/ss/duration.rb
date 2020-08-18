class SS::Duration
  def self.parse(name)
    num, unit = name.to_s.split('.', 2)
    raise "malformed duration: #{name}" if !num.numeric?

    num = num.to_i
    unit = "day" if unit.blank?
    case unit.singularize
    when "year"
      num.years
    when "month"
      num.months
    when "week"
      num.weeks
    when "day"
      num.days
    when "hour"
      num.hours
    when "minute"
      num.minutes
    when "second"
      num.seconds
    else
      raise "malformed duration: #{name}"
    end
  end
end
