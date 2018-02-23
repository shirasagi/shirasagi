namespace :gws do
  namespace :trash do
    task purge: :environment do
      site = Gws::Group.find_by(name: ENV['site'])
      threshold = ENV['threshold']
      params = []
      params << { threshold: threshold } if threshold.present?

      Gws::Schedule::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Schedule::TodoTrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Report::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Workflow::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Circular::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Monitor::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Board::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Faq::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Qna::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Discussion::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::Share::TrashPurgeJob.bind(site_id: site).perform_now(*params)
      Gws::SharedAddress::TrashPurgeJob.bind(site_id: site).perform_now(*params)
    end
  end
end
