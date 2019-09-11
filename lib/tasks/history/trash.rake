namespace :history do
  namespace :trash do
    task purge: :environment do
      site = Cms::Site.find_by(host: ENV['site']) if ENV['site'].present?
      threshold = ENV['threshold']
      params = []
      params << { threshold: threshold } if threshold.present?

      puts "delete history trashes"
      ::Rails.application.eager_load!
      History::Trash::TrashPurgeJob.bind(site_id: site).perform_now(*params)
    end
  end
end
