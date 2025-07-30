class Gws::Tabular::DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    date_value = value.to_s.in_time_zone rescue nil
    if date_value.nil?
      record.errors.add(attribute, options[:message] || :date)
    end
  end
end
