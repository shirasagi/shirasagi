class IpAddressValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    Array(value).each do |addr|
      next if addr.blank? || addr.start_with?("#")
      IPAddr.new(addr)
    end
  rescue
    record.errors.add(attribute, options[:message] || :invalid)
  end
end
