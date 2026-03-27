namespace :gws do
  namespace :main_group_orders do
    task update: :environment do
      ::Tasks::Gws::Base.each_sites do |site|
        puts "\# #{site.name}"
        ::Gws::UserMainGroupOrderUpdateJob.bind(site_id: site.id).perform_now
      end
    end
  end
end
