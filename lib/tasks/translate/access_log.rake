namespace :translate do
  namespace :access_log do
    task purge: :environment do
      sites = Cms::Site.all
      sites = site.where(host: ENV['site']) if ENV['site'].present?

      puts "delete translate access logs"
      ::Rails.application.eager_load!
      sites.each do |site|
        Translate::AccessLog::PurgeJob.bind(site_id: site).perform_now
      end
    end
  end
end
