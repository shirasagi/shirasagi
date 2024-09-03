namespace :gws do
  namespace :trash do
    task purge: :environment do
      threshold = ENV['threshold']
      params = []
      params << { threshold: threshold } if threshold.present?

      ::Tasks::Gws::Base.each_sites do |site|
        puts site.name
        ::Gws::Schedule::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Schedule::TodoTrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Report::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Workflow::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Workflow2::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Circular::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Monitor::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Board::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Faq::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Qna::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Discussion::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Share::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::SharedAddress::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Notice::TrashPurgeJob.bind(site_id: site).perform_now(*params)
        ::Gws::Survey::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      end
    end
  end
end
