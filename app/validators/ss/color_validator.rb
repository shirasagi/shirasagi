class SS::ColorValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    if !value.start_with?("#") || value.length != 7
      record.errors.add(attribute, options[:message] || :malformed_color)
      return
    end

    numeric_part = value[1..-1].downcase
    numeric_value = numeric_part.to_i(16)
    if numeric_value.to_s(16).rjust(6, "0") != numeric_part
      record.errors.add(attribute, options[:message] || :malformed_color)
      return
    end
  end
end
