namespace :rss do
  task import_items: :environment do
    ::Tasks::Cms.each_sites do |site|
      if ENV.key?("node")
        ::Tasks::Cms.with_node(site, ENV["node"]) do |node|
          Rss::ImportJob.register_job(site, node)
        end
      else
        Rss::ImportJob.register_jobs(site)
      end
    end

    Rake::Task["job:run"].invoke
  end

  task pull_weather_xml: :environment do
    Rss::ImportWeatherXmlJob.pull_all
  end
end
