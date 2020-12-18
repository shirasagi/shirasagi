class Rss::ImportWeatherXmlAllJob < SS::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = SS::Task
  self.task_name = "rss:import_weather_xml_all"

  def perform
    SS.config.rss.weather_xml["urls"].each do |url|
      pull_one(url)
    end
  end

  def pull_one(url)
    resp = download(url)
    return false if resp.status != 200

    content_encoding = resp.headers["Content-Encoding"]
    if content_encoding.nil?
      body = resp.body
    elsif content_encoding.casecmp("gzip") == 0
      body = Zlib::GzipReader.wrap(StringIO.new(resp.body)) { |gz| gz.read }
    end
    return false if body.blank?

    each_node do |node|
      site = node.site
      next if site.blank?

      @task.log "-- importing into #{node.name}(#{node.filename}) on #{site.name}(#{site.host})"

      elapsed = Benchmark.realtime do
        file = Rss::TempFile.create_from_post(site, body, resp.headers['Content-Type'].presence || "application/xml")
        job = Rss::ImportWeatherXmlJob.bind(site_id: site, node_id: node)
        job.perform_now(file.id)
      end

      @task.log "-- imported in #{elapsed} seconds"
    end

    true
  end

  private

  def on_each_retry(err, try, elapsed, interval)
    @task.log "#{err.class}: '#{err.message}' - #{try} tries in #{elapsed} seconds and #{interval} seconds until the next try."
  end

  def download(url)
    ret = nil

    @task.log "downloading #{url}"

    elapsed = Benchmark.realtime do
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
    end

    @task.log "downloaded #{url} with status #{ret.try(:status)} in #{elapsed} seconds"

    ret
  end

  def all_nodes
    @all_nodes ||= begin
      all_nodes = []
      all_ids = Rss::Node::WeatherXml.all.and_public.pluck(:id)
      all_ids.each_slice(20) do |ids|
        all_nodes += Rss::Node::WeatherXml.all.and_public.in(id: ids).to_a
      end
      all_nodes
    end
  end

  def each_node(&block)
    all_nodes.each(&block)
  end
end
