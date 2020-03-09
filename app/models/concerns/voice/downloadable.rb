require 'open-uri'
require 'resolv-replace'

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
      # class must provide a method 'url'
      options = {}
      options[:read_timeout] = timeout_sec
      options[:http_basic_authentication] = SS::MessageEncryptor.http_basic_authentication
      ::URI.open(url, options) do |f|
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
    @cached_page
  rescue
    Rails.logger.info("error was raised while downloading from #{url}")
    raise
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

  def with_retry(max_attempts)
    num_attempts = 0
    wait = initial_wait

    begin
      yield
    rescue Timeout::Error, StandardError => e
      Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join('\n  ')}")
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

      # remove query string and fragments.
      url = url.to_s.gsub(/\?.+$/, '').gsub(/#.+$/, '')

      if voice_file.url != url
        voice_file.url = url
        voice_file.save!
      end
      voice_file
    end

    private

    def find_site(url)
      host = url.host
      port = url.port
      path = url.path

      SS::Site.find_by_domain("#{host}:#{port}", path) || SS::Site.find_by_domain(host.to_s, path)
    end
  end
end
