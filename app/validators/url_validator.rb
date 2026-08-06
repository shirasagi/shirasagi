# frozen_string_literal: true

class UrlValidator < ActiveModel::EachValidator
  ALLOWED_SCHEMES = %w(http https).freeze

  class << self
    def valid?(value, **options)
      return true if value.blank?

      uri = ::Addressable::URI.parse(value)
      # 絶対パスの場合の検証
      if options[:absolute_path] && uri.scheme.blank? && value.start_with?("/")
        return true
      end

      # URLスキームの検証
      allowed_schemes = options[:scheme].try { |scheme| Array[scheme].flatten.map(&:to_s) } || ALLOWED_SCHEMES
      if !allowed_schemes.include?(uri.scheme)
        return false
      end

      true
    rescue
      false
    end
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    unless self.class.valid?(value, **options)
      record.errors.add(attribute, options[:message] || :url)
    end
  rescue
    record.errors.add(attribute, options[:message] || :url)
  end
end
