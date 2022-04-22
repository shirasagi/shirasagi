class SS::DurationValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    SS::Duration.parse(value)
  rescue => _e
    record.errors.add(attribute, options[:message] || :malformed_duration)
  end
end
