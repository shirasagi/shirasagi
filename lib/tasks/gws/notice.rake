namespace :gws do
  namespace :notice do
    namespace :notification do
      task deliver: :environment do
        gws_sites.each do |site|
          puts site.name
          Gws::Notice::NotificationJob.bind(site_id: site.id).perform_now
        end
      end
    end
  end
end
