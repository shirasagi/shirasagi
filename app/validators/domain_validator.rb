class DomainValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    values = value.is_a?(Array) ? value : [values]
    values.each do |val|
      next if val.blank?
      unless val.match(/^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6}(:[0-9]{1,5})?$/ix)
        record.errors.add(attribute, options[:message] || :domain)
      end
    end
  end
end
