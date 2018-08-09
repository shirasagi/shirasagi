namespace :event do
  task :import_icals => :environment do
    sites = ENV["site"] ? Cms::Site.where(host: ENV["site"]) : Cms::Site.all
    sites.each do |site|
      node = Event::Node::Ical.site(site).find_by(filename: ENV["node"]) if ENV["node"].present?

      if node.present?
        Event::Ical::ImportJob.register_job(site, node)
      else
        Event::Ical::ImportJob.register_jobs(site)
      end
    end

    Rake::Task["job:run"].invoke
  end
end
