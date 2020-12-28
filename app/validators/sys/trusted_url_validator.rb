class Sys::TrustedUrlValidator < ActiveModel::EachValidator
  class << self
    def myself_url?(url)
      return false if Rails.application.current_request.blank?

      url = ensure_addressable_url(url)
      request_url = ::Addressable::URI.parse(Rails.application.current_request.url)

      if url.host.present?
        return false if url.host != request_url.host
      end
      if url.port.present?
        return false if url.port != request_url.port
      end

      true
    end

    def trusted_url?(url, known_trusted_urls = nil)
      url = ensure_addressable_url(url)

      if known_trusted_urls.present?
        return true if parse_urls(known_trusted_urls).any? do |trusted_url|
          trusted_url_one?(trusted_url, url) && trusted_url.path == url.path
        end
      end

      if trusted_urls.any? { |trusted_url| trusted_url_one?(trusted_url, url) }
        return true
      end

      false
    end

    def valid_url?(url, known_trusted_urls = nil)
      return true if myself_url?(url)
      return true if trusted_url?(url, known_trusted_urls)

      false
    end

    private

    def ensure_addressable_url(url)
      return url if url.respond_to?(:scheme)
      ::Addressable::URI.parse(url.to_s)
    end

    def trusted_url_one?(trusted_template_url, uncertain_url)
      if trusted_template_url.scheme.present?
        return false if uncertain_url.scheme != trusted_template_url.scheme
      end
      if trusted_template_url.host.present?
        return false if uncertain_url.host != trusted_template_url.host
      end
      if trusted_template_url.port.present?
        return false if uncertain_url.port != trusted_template_url.port
      end
      if trusted_template_url.path.present?
        return false unless uncertain_url.path.start_with?(trusted_template_url.path)
      end

      true
    end

    def parse_urls(sources)
      return [] if sources.blank?

      sources.uniq.sort.map do |source|
        ensure_addressable_url(source) rescue nil
      end.compact
    end

    def trusted_urls
      @trusted_urls ||= parse_urls(SS.config.sns.trusted_urls)
    end

    def clear_trusted_urls
      @trusted_urls = nil
    end
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    known_trusted_urls = []
    if record.respond_to?(:site) && record.site.present?
      if record.site.respond_to?(:full_url) && record.site.full_url.present?
        known_trusted_urls << "//#{record.site.domain_with_subdir}"
      end
    end

    url = ::Addressable::URI.parse(value)
    return if self.class.valid_url?(url, known_trusted_urls)

    record.errors.add(attribute, options[:message] || :trusted_url)
  rescue Addressable::URI::InvalidURIError => _e
    record.errors.add(attribute, options[:message] || :trusted_url)
  end
end
