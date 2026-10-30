class Sys::TrustedUrlValidator < ActiveModel::EachValidator
  ALLOWED_SCHEMES = Set.new(%w(http https)).freeze
  # ホストが必須のスキーム。"https:/evil.example" のようにホストがないと、ブラウザは path をホストとして解釈する
  HOST_REQUIRED_SCHEMES = Set.new(%w(http https)).freeze
  CONTROL_CHARS = /[\x00-\x1F\x7F]/

  class << self
    def myself_url?(url)
      return false if Rails.application.current_request.blank?

      url = normalize_url!(url) rescue nil
      return false unless url
      return false if ambiguous_url?(url)

      request_url = ::Addressable::URI.parse(Rails.application.current_request.url) rescue nil
      return false unless request_url

      if url.scheme.present? && !ALLOWED_SCHEMES.include?(url.scheme.downcase)
        return false
      end
      if url.host.present? && url.host != request_url.host
        return false
      end
      if url.port.present? && url.port != request_url.port
        return false
      end

      true
    end

    def trusted_url?(url, known_trusted_urls = nil)
      url = normalize_url!(url) rescue nil
      return false unless url
      return false if ambiguous_url?(url)
      return true if url.scheme.blank? && url.host.blank? && url.port.blank?

      if known_trusted_urls.present?
        if parse_urls(known_trusted_urls).any? { |trusted_url| trusted_url_one?(trusted_url, url) }
          return true
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

    def url_type
      @url_type ||= SS.config.sns.url_type || "restricted"
    end

    def url_restricted?
      url_type == "restricted"
    end

    def trusted_urls
      @trusted_urls ||= parse_urls(SS.config.sns.trusted_urls)
    end

    private

    def ensure_addressable_url!(url)
      return url if url.respond_to?(:scheme)
      ::Addressable::URI.parse(url.to_s)
    end

    # ブラウザ(WHATWG URL)と同様に、前後の空白・制御文字と途中のタブ・改行を除去してから解析する
    def normalize_url!(url)
      source = url.to_s
      normalized = source.gsub(/\A[\x00-\x20]+|[\x00-\x20]+\z/, "").delete("\t\n\r")
      return ensure_addressable_url!(url) if normalized == source

      ::Addressable::URI.parse(normalized)
    end

    # Addressable とブラウザとで解釈が異なり、ブラウザでは外部ホストを指す恐れのある URL か
    def ambiguous_url?(url)
      return true if url.to_s.match?(CONTROL_CHARS)
      # "https://example.jp@evil.example/" のような偽装や、"https://evil.example\@example.jp/" のように
      # ブラウザが "\" を "/" として扱うことによるパーサー差異を防ぐ
      return true if url.userinfo.present?
      return true if url.authority.present? && url.authority.include?("\\")

      if url.scheme.blank?
        # "///evil.example" や "/\evil.example" は、ブラウザでは "//evil.example" と解釈される
        return true if url.authority == ""
        return true if url.authority.nil? && url.path.match?(%r{\A[/\\]{2}})
      elsif HOST_REQUIRED_SCHEMES.include?(url.scheme.downcase)
        # "https:/evil.example" や "https:///evil.example" は、ブラウザでは "https://evil.example" と解釈される
        return true if url.host.blank?
      end

      false
    end

    def trusted_url_one?(trusted_template_url, uncertain_url)
      if trusted_template_url.scheme.present?
        if uncertain_url.scheme != trusted_template_url.scheme
          return false
        end
      end
      if uncertain_url.scheme.present? && !ALLOWED_SCHEMES.include?(uncertain_url.scheme.downcase)
        return false
      end
      if trusted_template_url.host.present?
        if trusted_template_url.host.include?("*")
          # wildcard host
          pattern = Regexp.escape(trusted_template_url.host).gsub('\*', '.*?')
          regex = Regexp.new("\\A#{pattern}\\z", Regexp::IGNORECASE)
          return false unless regex.match?(uncertain_url.host)
        else
          return false if uncertain_url.host != trusted_template_url.host
        end
      end
      if trusted_template_url.port.present? && uncertain_url.port != trusted_template_url.port
        return false
      end
      if trusted_template_url.path.present? && !uncertain_url.path.start_with?(trusted_template_url.path)
        return false
      end

      true
    end

    def parse_urls(sources)
      return [] if sources.blank?

      sources.uniq.sort.map do |source|
        ensure_addressable_url!(source) rescue nil
      end.compact
    end

    def clear_trusted_urls
      @url_type = nil
      @trusted_urls = nil
    end
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    known_trusted_urls = []
    %i[cur_site site].each do |m|
      next unless record.respond_to?(m)

      site = record.send(m)
      next if site.blank?
      next unless site.respond_to?(:domain_with_subdir)

      domain_with_subdir = site.domain_with_subdir
      next if domain_with_subdir.blank?

      known_trusted_urls << "//#{domain_with_subdir}"
      break
    end

    if record.fields[attribute.to_s].localized?
      return if value.values.all? do |url|
        url = ::Addressable::URI.parse(url) rescue nil
        next false unless url
        self.class.valid_url?(url, known_trusted_urls)
      end
    else
      url = ::Addressable::URI.parse(value) rescue nil
      return if url && self.class.valid_url?(url, known_trusted_urls)
    end

    record.errors.add(attribute, options[:message] || :trusted_url)
  rescue Addressable::URI::InvalidURIError => _e
    record.errors.add(attribute, options[:message] || :trusted_url)
  end
end
