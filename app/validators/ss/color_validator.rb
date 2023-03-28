class SS::ColorValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    if SS::Color.parse(value).blank?
      record.errors.add(attribute, options[:message] || :malformed_color)
      return
    end
  end
end
