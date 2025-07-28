class Gws::Tabular::DatetimeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    datetime_value = value.to_s.in_time_zone rescue nil
    if datetime_value.nil?
      record.errors.add(attribute, options[:message] || :datetime)
    end
  end
end
