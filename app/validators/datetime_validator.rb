class DatetimeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    # https://github.com/mongodb/mongoid/pull/4279
    # invalid date or empty value given by nil.
    # but these are indistinguishable.

    #if value == ::Date::EPOCH || value == ::Time::EPOCH
    #  record.errors.add(attribute, options[:message] || :invalid)
    #end
  end
end
