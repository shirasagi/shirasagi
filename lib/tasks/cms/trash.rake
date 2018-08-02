namespace :cms do
  namespace :trash do
    task purge: :environment do
      site = Cms::Site.find_by(host: ENV['site'])
      threshold = ENV['threshold']
      params = []
      params << { threshold: threshold } if threshold.present?

      Cms::Layout::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Cms::Node::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Cms::Page::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Cms::Part::TrashPurgeJob.bind(site_id: site).perform_now(*params)
    end
  end
end
