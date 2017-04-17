namespace :ezine do
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

  task :deliver => :environment do
    with_site(Ezine::DeliverReservedJob)
  end
end
