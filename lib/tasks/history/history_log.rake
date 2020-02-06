namespace :history do
  namespace :history_log do
    task purge: :environment do
      sites = Cms::Site.all
      sites = site.where(host: ENV['site']) if ENV['site'].present?
      threshold = ENV['purge_threshold'] || ENV['threshold']
      params = []
      params << { threshold: threshold } if threshold.present?

      puts "delete history logs"
      ::Rails.application.eager_load!
      sites.each do |site|
        History::HistoryLog::PurgeJob.bind(site_id: site).perform_now(*params)
      end
    end
  end
end
