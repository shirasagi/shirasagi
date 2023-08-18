class LiquidFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    Liquid::Template.parse(value.to_s, error_mode: :strict)
  rescue Liquid::Error => e
    record.errors.add(attribute, options[:message] || :malformed_liquid_template, error: e.to_s)
  end
end
