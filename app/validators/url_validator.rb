# frozen_string_literal: true

class UrlValidator < ActiveModel::EachValidator
  ALLOWED_SCHEMES = Set.new(%w(http https)).freeze

  class << self
    def valid?(value, **options)
      return true if value.blank?

      uri = ::Addressable::URI.parse(value)
      if uri.path.present?
        path_type = check_path_type(uri)
        return false unless path_type
      end

      allowed_path_types = Set.new

      # 絶対パスの場合の検証
      allowed_path_types.add(:absolute) if options[:absolute_path]
      # 相対パスの場合
      allowed_path_types.add(:relative) if options[:relative_path]
      if allowed_path_types.present? && uri.scheme.blank?
        return true if allowed_path_types.include?(path_type)
        return true if uri.path.blank? && uri.host.present?
      end

      # URLスキームの検証
      allowed_schemes = options[:scheme].try { |scheme| Array[scheme].flatten.map { _1.to_s.downcase } }
      allowed_schemes ||= ALLOWED_SCHEMES
      unless allowed_schemes.include?(uri.scheme.try(:downcase))
        return false
      end

      true
    rescue
      false
    end

    private

    def check_path_type(uri)
      unencoded = Addressable::URI.unencode_component(uri.path)
      expanded = File.expand_path(unencoded, "/")
      if expanded == unencoded || "#{expanded}/" == unencoded
        :absolute
      elsif !unencoded.include?("\\") && (expanded[1..-1] == unencoded || "#{expanded[1..-1]}/" == unencoded)
        :relative
      else
        # ./ や ../ を含んでいるとNGとする
        nil
      end
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
