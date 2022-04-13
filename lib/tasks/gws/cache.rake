namespace :gws do
  namespace :cache do
    task rebuild: :environment do
      ::Tasks::Gws::Base.each_sites do |site|
        next if Gws::Role.site(site).empty?

        Gws::CacheRebuildJob.bind(site_id: site).perform_now
      end
    end
  end
end
