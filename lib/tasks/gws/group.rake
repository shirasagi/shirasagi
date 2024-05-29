namespace :gws do
  task reload_site_usage: :environment do
    puts "# reload site usage"
    ::Tasks::Gws::Base.each_sites do |site|
      puts site.name
      Gws::ReloadSiteUsageJob.bind(site_id: site).perform_now
    end
  end
end
