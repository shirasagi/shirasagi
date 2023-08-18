class EmailValidator < ActiveModel::EachValidator
  REGEXP = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  def validate_each(record, attribute, value)
    return if value.blank?

    if @options && @options[:rfc2822]
      value = Mail::Address.new(value).address
      if value.blank?
        record.errors.add(attribute, options[:message] || :email)
        return
      end
    end

    record.errors.add(attribute, options[:message] || :email) unless value =~ REGEXP
  end
end
