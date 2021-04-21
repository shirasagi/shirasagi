class EmailsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    value = [ value ].flatten.select(&:present?)
    return if value.blank?

    record.errors.add(attribute, options[:message] || :email) unless value.all? { |v| v =~ EmailValidator::REGEXP }
  end
end
