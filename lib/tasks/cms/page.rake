namespace :cms do
  def find_sites(site)
    return Cms::Site unless site
    Cms::Site.where host: site
  end

  task :generate_nodes => :environment do
    find_sites(ENV["site"]).each do |site|
      job = Cms::Node::GeneratorJob.bind(site_id: site)
      job = job.bind(node_id: ENV["node"]) if ENV["node"]
      job.perform_now
    end
  end

  task :generate_pages => :environment do
    find_sites(ENV["site"]).each do |site|
      job = Cms::Page::GeneratorJob.bind(site_id: site)
      job = job.bind(node_id: ENV["node"]) if ENV["node"]
      job.perform_now
    end
  end

  task :update_pages => :environment do
    Cms::Task.update_pages site: ENV["site"], node: ENV["node"]
  end

  task :release_pages => :environment do
    Cms::Task.release_pages site: ENV["site"]
  end

  task :remove_pages => :environment do
    Cms::Task.remove_pages site: ENV["site"]
  end

  task :check_links => :environment do
    Cms::Task.check_links site: ENV["site"], node: ENV["node"], email: ENV["email"]
  end
end
