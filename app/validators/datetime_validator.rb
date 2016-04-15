class DatetimeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    if value == ::Date::EPOCH || value == ::Time::EPOCH
      record.errors.add(attribute, options[:message] || :invalid)
    end
  end
end
