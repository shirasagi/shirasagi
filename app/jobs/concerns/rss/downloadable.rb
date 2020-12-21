module Rss::Downloadable
  extend ActiveSupport::Concern

  included do
    cattr_accessor :data_cache_dir, instance_accessor: false
    self.data_cache_dir = ::File.expand_path(SS.config.rss.weather_xml["data_cache_dir"], Rails.root)
  end

  def download(url)
    ret = nil

    Retriable.retriable(on_retry: method(:on_each_retry)) do
      http_client = Faraday.new(url: url) do |builder|
        builder.request  :url_encoded
        builder.response :logger, Rails.logger
        builder.adapter Faraday.default_adapter
      end
      http_client.headers[:user_agent] += " (SHIRASAGI/#{SS.version}; PID/#{Process.pid})"
      http_client.headers[:accept_encoding] = "gzip"

      ret = http_client.get
    end

    body = extract_body(ret)
    [ ret, body ]
  end

  def download_with_cache(url, options = {})
    resp = nil
    body = nil

    @task.log "downloading #{url}"

    ::FileUtils.mkdir_p(self.class.data_cache_dir) unless ::Dir.exists?(self.class.data_cache_dir)

    hash = Digest::MD5.hexdigest(url)
    file_paths = %w(xml.gz xml).map { |ext| ::File.join(self.class.data_cache_dir, "#{hash}.#{ext}") }

    unless options[:updates]
      file_path = file_paths.find { |path| ::File.exists?(path) }
      if file_path
        if file_path.ends_with?(".gz")
          body = ::Zlib::GzipReader.open(file_path) { |gz| gz.read }
        else
          body = ::File.read(file_path)
        end
      end

      if body.present?
        @task.log "found #{url} in cache"
        return body
      end
    end

    elapsed = Benchmark.realtime do
      resp, body = download(url)
    end

    @task.log "downloaded #{url} with status #{resp.try(:status)} in #{elapsed} seconds"

    if resp.status == 200 && body.present?
      ::Zlib::GzipWriter.open(file_paths.first) { |gz| gz.write(body.to_s) }
    end

    body
  end

  def remove_old_cache(threshold)
    ::Dir.glob(%w(*.xml *.xml.gz), base: self.class.data_cache_dir).each do |file_path|
      file_path = ::File.expand_path(file_path, self.class.data_cache_dir)
      ::FileUtils.rm_f(file_path) if ::File.mtime(file_path) < threshold
    end
  end

  private

  def on_each_retry(err, try, elapsed, interval)
    @task.log "#{err.class}: '#{err.message}' - #{try} tries in #{elapsed} seconds and #{interval} seconds until the next try."
  end

  def extract_body(resp)
    return if resp.blank? || resp.status != 200

    content_encoding = resp.headers["Content-Encoding"]
    if content_encoding.nil?
      body = resp.body
    elsif content_encoding.casecmp("gzip") == 0
      body = Zlib::GzipReader.wrap(StringIO.new(resp.body)) { |gz| gz.read }
    end

    body.strip.presence
  end
end
