namespace :rss do
  task :import_items => :environment do
    sites = ENV["site"] ? Cms::Site.where(host: ENV["site"]) : Cms::Site.all
    sites.each do |site|
      node = Rss::Node::Page.site(site).find_by(filename: ENV["node"])

      if node.present?
        Rss::ImportJob.register_job(site, node)
      else
        Rss::ImportJob.register_jobs(site)
      end
    end

    Rake::Task["job:run"].invoke
  end
end
