# frozen_string_literal: true

class UrlValidator < ActiveModel::EachValidator
  ALLOWED_SCHEMES = %w(http https).freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    uri = ::URI.parse(value)

    allowed_schemes = options[:scheme].try { |scheme| Array[scheme].flatten.map(&:to_s) } || ALLOWED_SCHEMES
    if !allowed_schemes.include?(uri.scheme)
      record.errors.add(attribute, options[:message] || :url)
      return
    end
  rescue
    record.errors.add(attribute, options[:message] || :url)
  end
end
