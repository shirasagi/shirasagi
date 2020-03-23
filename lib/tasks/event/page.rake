namespace :event do
  task import_icals: :environment do
    ::Tasks::Cms.each_sites do |site|
      if ENV.key?("node")
        ::Tasks::Cms.with_node(site, ENV["node"]) do |node|
          Event::Ical::ImportJob.perform_job(site, node)
        end
      else
        Event::Ical::ImportJob.perform_jobs(site)
      end
    end
  end
end
