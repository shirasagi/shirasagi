class Rss::ImportWeatherXmlAllJob < SS::ApplicationJob
  include Job::SS::TaskFilter
  include Rss::Downloadable

  self.task_class = SS::Task
  self.task_name = "rss:import_weather_xml_all"

  def perform
    urls = SS.config.rss.weather_xml["urls"]
    urls.map!(&:strip)
    urls.select!(&:present?)
    @task.log "found #{urls.length} seeds"

    urls.each do |url|
      download_with_cache(url, updates: true)
    end

    each_node do |node|
      site = node.site
      next if site.blank?

      @task.log "-- importing into #{node.name}(#{node.filename}) on #{site.name}(#{site.host})"

      elapsed = Benchmark.realtime do
        job = Rss::ImportWeatherXmlJob.bind(site_id: site, node_id: node)
        job.perform_now(seed_cache: 'use')
      end

      @task.log "-- imported in #{elapsed} seconds"
    end
  end

  private

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
