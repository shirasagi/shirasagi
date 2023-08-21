namespace :gws do
  namespace :aggregation do
    namespace :group do
      task update: :environment do
        puts "# gws/aggregation : update aggregation groups"
        ::Tasks::Gws::Base.each_sites do |site|
          puts "\# #{site.name}"
          ::Gws::Aggregation::GroupUpdateJob.bind(site_id: site.id).perform_now
        end
      end
    end
  end
end
