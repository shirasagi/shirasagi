class Sys::TrustedUrlValidator < ActiveModel::EachValidator
  class << self
    def myself_url?(url)
      return false if Rails.application.current_request.blank?

      request_url = ::Addressable::URI.parse(Rails.application.current_request.url)
      url.scheme == request_url.scheme && url.host == request_url.host && url.port == request_url.port
    end

    def trusted_url?(url, known_trusted_urls = nil)
      url = url.to_s

      if known_trusted_urls.present?
        return true if known_trusted_urls.any? { |trusted_url| url.start_with?(trusted_url) }
      end

      if SS.config.sns.trusted_urls.blank?.present?
        return true if SS.config.sns.trusted_urls.any? { |trusted_url| url.start_with?(trusted_url) }
      end

      false
    end

    def valid_url?(url, known_trusted_urls = nil)
      if url.relative?
        return url.path.present? && url.path[0] == "/"
      end

      return true if myself_url?(url)
      return true if trusted_url?(url, known_trusted_urls)

      false
    end
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    known_trusted_urls = []
    if record.respond_to?(:site) && record.site.present?
      if record.site.respond_to?(:full_url) && record.site.full_url.present?
        known_trusted_urls << record.site.full_url
      end
    end

    url = ::Addressable::URI.parse(value)
    return if self.class.valid_url?(url, known_trusted_urls)

    record.errors.add(attribute, options[:message] || :trusted_url)
  rescue Addressable::URI::InvalidURIError => _e
    record.errors.add(attribute, options[:message] || :trusted_url)
  end
end
