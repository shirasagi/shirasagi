class EmailValidator < ActiveModel::EachValidator
  REGEXP = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  def validate_each(record, attribute, value)
    return if value.blank?
    record.errors.add(attribute, options[:message] || :email) unless value =~ REGEXP
  end
end
