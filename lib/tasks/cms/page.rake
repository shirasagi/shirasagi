namespace :cms do
  def find_sites(site)
    return Cms::Site unless site
    Cms::Site.where host: site
  end

  def with_site(job_class, opts = {})
    find_sites(ENV["site"]).each do |site|
      job = job_class.bind(site_id: site)
      job.perform_now(opts)
    end
  end

  def with_node(job_class, opts = {})
    find_sites(ENV["site"]).each do |site|
      job = job_class.bind(site_id: site)
      job = job.bind(node_id: ENV["node"]) if ENV["node"]
      job.perform_now(opts)
    end
  end

  task :generate_nodes => :environment do
    with_node(Cms::Node::GenerateJob)
  end

  task :generate_pages => :environment do
    with_node(Cms::Page::GenerateJob, attachments: ENV["attachments"])
  end

  task :update_pages => :environment do
    with_node(Cms::Page::UpdateJob)
  end

  task :release_pages => :environment do
    with_site(Cms::Page::ReleaseJob)
  end

  task :remove_pages => :environment do
    with_site(Cms::Page::RemoveJob)
  end

  task :check_links => :environment do
    with_node(Cms::CheckLinksJob, email: ENV["email"])
  end
end
