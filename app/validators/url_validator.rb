# frozen_string_literal: true

class UrlValidator < ActiveModel::EachValidator
  ALLOWED_SCHEMES = Set.new(%w(http https)).freeze
  # ホストが必須のスキーム。"https:/evil.example" のようにホストがないと、ブラウザは path をホストとして解釈する
  HOST_REQUIRED_SCHEMES = Set.new(%w(http https)).freeze
  # 制御文字(ブラウザはタブや改行を除去して解釈する)
  CONTROL_CHARS = /[\x00-\x1F\x7F]/
  # 制御文字に加え、エンコードせずに URL に含めてはならず、属性インジェクションの原因となる文字
  UNSAFE_CHARS = /[\x00-\x1F\x7F"<>`]/

  class << self
    def valid?(value, **options)
      return true if value.blank?
      return false if value.match?(UNSAFE_CHARS)

      uri = ::Addressable::URI.parse(value)
      return false if unsafe_authority?(uri)
      return false if options[:only_path] && (uri.scheme.present? || uri.authority.present?)

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
      valid_scheme?(uri, options[:scheme])
    rescue
      false
    end

    private

    def valid_scheme?(uri, scheme_option)
      allowed_schemes = scheme_option.try { |scheme| Array[scheme].flatten.map { _1.to_s.downcase } }
      allowed_schemes ||= ALLOWED_SCHEMES
      scheme = uri.scheme.try(:downcase)
      return false unless allowed_schemes.include?(scheme)
      return false if HOST_REQUIRED_SCHEMES.include?(scheme) && uri.host.blank?

      true
    end

    def unsafe_authority?(uri)
      # "///evil.example" のような空の authority は、ブラウザでは "//evil.example" と解釈される
      return true if uri.scheme.blank? && uri.authority == ""
      # "https://example.jp@evil.example/" や "https://evil.example\@example.jp/" のようなパーサー差異・偽装を防ぐ
      return true if uri.userinfo.present?
      return true if uri.authority.present? && uri.authority.include?("\\")

      false
    end

    def check_path_type(uri)
      unencoded = Addressable::URI.unencode_component(uri.path)
      # ブラウザは "\" を "/" として扱うため、"/\evil.example" は "//evil.example" と解釈される
      return if unencoded.include?("\\") || unencoded.match?(CONTROL_CHARS)
      # authority のない "//" で始まるパスは、ブラウザではホストとして解釈される
      return if uri.authority.nil? && unencoded.start_with?("//")

      expanded = File.expand_path(unencoded, "/")
      if expanded == unencoded || "#{expanded}/" == unencoded
        :absolute
      elsif expanded[1..-1] == unencoded || "#{expanded[1..-1]}/" == unencoded
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
