module Rss::Downloadable
  extend ActiveSupport::Concern

  class DownloadError < StandardError; end

  included do
    cattr_accessor :data_cache_dir, instance_accessor: false
    self.data_cache_dir = ::File.expand_path(SS.config.rss.weather_xml["data_cache_dir"], Rails.root)
  end

  def download(url)
    resp = nil

    Retriable.retriable(on_retry: method(:on_each_retry)) do
      http_client = Faraday.new(url: url) do |builder|
        builder.request  :url_encoded
        builder.response :logger, Rails.logger
        builder.adapter Faraday.default_adapter
      end
      http_client.headers[:user_agent] += " (SHIRASAGI/#{SS.version}; PID/#{Process.pid})"
      http_client.headers[:accept_encoding] = "gzip"

      resp = http_client.get
      raise DownloadError, "got \"#{resp.reason_phrase}\"(#{resp.status}) for #{url}" unless resp.status == 200
    end

    body = extract_body(resp)
    [ resp, body ]
  rescue DownloadError => _e
    [ resp, nil ]
  end

  def download_with_cache(url, options = {})
    resp = nil
    body = nil

    @task.log "downloading #{url}"

    ::FileUtils.mkdir_p(self.class.data_cache_dir) unless ::Dir.exists?(self.class.data_cache_dir)

    hash = Digest::MD5.hexdigest(url)

    unless options[:updates]
      body = find_in_cache(hash)
      if body.present?
        @task.log "found #{url} in cache"
        return body
      end
    end

    elapsed = Benchmark.realtime do
      resp, body = download(url)
    end

    @task.log "downloaded #{url} with status #{resp.try(:status)} in #{elapsed} seconds"

    save_in_cache(hash, body) if resp && resp.status == 200 && body.present?

    body
  end

  def remove_old_cache(threshold)
    ::Dir.glob(%w(*.xml *.xml.gz *.log.gz), base: self.class.data_cache_dir).each do |file_path|
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

  def find_in_cache(hash)
    file_paths = %w(xml.gz xml).map { |ext| ::File.join(self.class.data_cache_dir, "#{hash}.#{ext}") }
    file_path = file_paths.find { |path| ::File.exists?(path) }
    return if file_path.blank?

    if file_path.ends_with?(".gz")
      ::Zlib::GzipReader.open(file_path) { |gz| gz.read }
    else
      ::File.read(file_path)
    end
  end

  def save_in_cache(hash, body)
    file_path = ::File.join(self.class.data_cache_dir, "#{hash}.xml.gz")
    tmp_file_path = ::File.join(self.class.data_cache_dir, ".#{hash}.xml.gz")

    # DISK FULL などにより不完全なファイルが作成されることを防止するために、作業ファイルに保存後、作業ファイルを移動するようにする。
    ::Zlib::GzipWriter.open(tmp_file_path) { |gz| gz.write(body.to_s) }
    ::FileUtils.move(tmp_file_path, file_path, force: true)
  end
end
