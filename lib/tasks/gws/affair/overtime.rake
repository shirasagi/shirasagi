namespace :gws do
  namespace :affair do
    namespace :overtime do
      task aggregate: :environment do
        site = ::Gws::Group.where(name: { "$not" => /\// }).first
        ::Gws::Affair::OvertimeAggregateJob.bind(site_id: site.id).perform_now
      end
    end
  end
end
