namespace :history do
  namespace :trash do
    task purge: :environment do
      sites = Cms::Site.all
      sites = site.where(host: ENV['site']) if ENV['site'].present?
      threshold = ENV['threshold']
      params = []
      params << { threshold: threshold } if threshold.present?

      puts "delete history trashes"
      ::Rails.application.eager_load!
      sites.each do |site|
        History::Trash::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      end
    end
  end
end
