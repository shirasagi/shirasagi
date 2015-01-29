require 'open-uri'
require 'resolv-replace'
require 'timeout'

module Voice::Downloadable
  extend ActiveSupport::Concern

  attr_accessor :cached_page

  included do
    field :url, type: String
    field :path, type: String
    field :page_identity, type: String
  end

  def download
    return @cached_page if @cached_page

    @cached_page = with_retry(max_attempts) do
      timeout(timeout_sec) do
        # class must provide a method 'url'
        options = {}
        options[:read_timeout] = timeout_sec
        options[:http_basic_authentication] = decrypt(basic_auth) if basic_auth.present?
        open(url, options) do |f|
          status_code = f.status[0]

          html = f.read if status_code == '200'
          html.force_encoding("utf-8") if html
          page_identity = make_page_identity(html, f.meta['etag'], f.last_modified)

          page = {
            html: html,
            page_identity: page_identity
          }
          OpenStruct.new(page)
        end
      end
    end
    @cached_page
  end

  def same_identity?
    download
    page_identity == @cached_page.page_identity
  end

  private
    def max_attempts
      @max_attempts ||= SS.config.voice.download['max_attempts']
    end

    def initial_wait
      @initial_wait ||= SS.config.voice.download['initial_wait']
    end

    def timeout_sec
      @timeout_sec ||= SS.config.voice.download['timeout_sec']
    end

    def basic_auth
      @basic_auth ||= SS.config.voice.download['basic_auth']
    end

    def with_retry(max_attempts)
      num_attempts = 0
      wait = initial_wait

      begin
        yield
      rescue TimeoutError, StandardError
        num_attempts += 1
        raise if num_attempts >= max_attempts

        sleep wait
        wait *= 2
        retry
      end
    end

    def make_page_identity(html, _, _)
      Digest::MD5.hexdigest(purge_csrf_token(html))
    end

    def purge_csrf_token(html)
      html.gsub!(/<\s*meta\s+content\s*=\s*["']authenticity_token["']\s+name\s*=\s*["']csrf-param["']\s*\/>/, '')
      html.gsub!(/<\s*meta\s+content\s*=\s*["'].+?["']\s+name\s*=\s*["']csrf-token["']\s*\/>/, '')
      html
    end

    def decrypt(auth)
      secrets = Rails.application.secrets[:secret_key_base]
      encryptor = ::ActiveSupport::MessageEncryptor.new(secrets, cipher: 'aes-256-cbc')
      begin
        auth[0] = encryptor.decrypt_and_verify(auth[0])
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        # ignore
      end

      begin
        auth[1] = encryptor.decrypt_and_verify(auth[1])
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        # ignore
      end
    end

  module ClassMethods
    def find_or_create_by_url(url)
      url = ::URI.parse(url.to_s) unless url.respond_to?(:host)
      if url.host.blank? || url.path.blank?
        # path must not be either nil, empty.
        return nil
      end
      url.normalize!

      site = find_site url
      unless site
        Rails.logger.debug("site is not found: #{url}")
        return nil
      end

      voice_file = self.find_or_create_by site_id: site.id, path: url.path
      if voice_file.url.blank?
        # remove query string and fragments.
        voice_file.url = url.to_s.gsub(/\?.+$/, '').gsub(/#.+$/, '')
        voice_file.save!
      end
      voice_file
    end

    private
      def find_site(url)
        host = url.host
        port = url.port

        SS::Site.find_by_domain("#{host}:#{port}") || SS::Site.find_by_domain("#{host}")
      end
  end
end
