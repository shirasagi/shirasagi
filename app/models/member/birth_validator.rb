class Member::BirthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    calendar = find_by_era(value[:era])
    if calendar.blank?
      record.errors.add(:base, :invalid_era, options.merge(value: value[:era]))
      return
    end

    year = value[:year]
    unless year =~ /\A[+-]?\d+\z/
      record.errors.add(:base, :not_an_integer, options.merge(value: value[:year]))
      return
    end

    month = value[:month]
    unless month =~ /\A[+-]?\d+\z/
      record.errors.add(:base, :not_an_integer, options.merge(value: value[:month]))
      return
    end

    day = value[:day]
    unless day =~ /\A[+-]?\d+\z/
      record.errors.add(:base, :not_an_integer, options.merge(value: value[:day]))
      return
    end

    year = year.to_i
    month = month.to_i
    day = day.to_i

    unless include_year_range?(calendar, year)
      record.errors.add(:base, :year_out_of_range, options.merge(value: value[:year]))
      return
    end

    unless include_month_range?(calendar, year, month)
      record.errors.add(:base, :month_out_of_range, options.merge(value: value[:month]))
      return
    end

    unless include_day_range?(calendar, year, month, day)
      record.errors.add(:base, :day_out_of_range, options.merge(value: value[:day]))
      return
    end
  end

  private
    def find_by_era(era)
      wareki = SS.config.ss.wareki[era]
      return nil if wareki.blank?
      min = Date.parse(wareki['min'])
      max = Date.parse(wareki['max'])

      [min, max]
    end

    def include_year_range?(setting, year)
      min, max = setting
      1 <= year && (min.year + year - 1) <= max.year
    end

    def include_month_range?(setting, year, month)
      min, max = setting
      1 <= month && month <= 12 && Date.new(min.year + year - 1, month, 1) < max
    end

    def include_day_range?(setting, year, month, day)
      min, max = setting
      1 <= day && day <= 31 && Date.new(min.year + year - 1, month, day) < max
    end
end
