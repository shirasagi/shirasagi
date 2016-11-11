namespace :recommend do
  task :create_similarity_scores => :environment do
    site = Cms::Site.where(host: ENV["site"]).first
    puts "Please input site_name: site=[site_name]" or exit unless site

    job = Recommend::CreateSimilarityScoresJob.bind(site_id: site.id)
    job.perform_now(ENV["days"])
  end

  task :destroy_similarity_scores => :environment do
    site = Cms::Site.where(host: ENV["site"]).first

    job = Recommend::DestroySimilarityScoresJob
    job = job.bind(site_id: site.id) if site
    job.perform_now()
  end

  task :destroy_history_logs => :environment do
    site = Cms::Site.where(host: ENV["site"]).first

    job = Recommend::DestroyHistoryLogsJob
    job = job.bind(site_id: site.id) if site
    job.perform_now()
  end
end
