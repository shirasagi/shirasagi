namespace :rss do
  task :import_pages => :environment do
    find_sites(ENV["site"]).each do |site|
      node = find_node(site, ENV["node"])

      if node.present?
        Rss::ImportJob.register_job(site, node)
      else
        Rss::ImportJob.register_jobs(site)
      end
    end

    run_job
  end

  def find_sites(site)
    return Cms::Site unless site
    Cms::Site.where host: site
  end

  def find_node(site, node)
    return nil unless node
    Rss::Node::Page.site(site).find_by filename: node
  end

  def run_job
    # call job:run task
    Rake::Task["job:run"].invoke
  end
end
