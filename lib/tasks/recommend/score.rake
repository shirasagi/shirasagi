namespace :recommend do
  task create_similarity_scores: :environment do
    ::Tasks::Cms.with_site(ENV['site']) do |site|
      job = Recommend::CreateSimilarityScoresJob.bind(site_id: site.id)
      job.perform_now(ENV["days"])
    end
  end

  task destroy_similarity_scores: :environment do
    site = Cms::Site.where(host: ENV["site"]).first

    job = Recommend::DestroySimilarityScoresJob
    job = job.bind(site_id: site.id) if site
    job.perform_now
  end

  task destroy_history_logs: :environment do
    site = Cms::Site.where(host: ENV["site"]).first

    job = Recommend::DestroyHistoryLogsJob
    job = job.bind(site_id: site.id) if site
    job.perform_now
  end
end
