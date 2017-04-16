namespace :voice do
  task :setup_logger => [:environment] do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::DEBUG
  end

  task :purge => [:environment, :setup_logger] do
    site = ENV["site"]
    next if site.blank?

    cur_site = SS::Site.where(host: site).first
    next if cur_site.blank?

    criteria = Job::Task.site(cur_site).where(pool: 'voice_synthesis')
    next if criteria.count <= 20
    count = criteria.where(started: nil).lt(created: 5.minutes.ago).destroy
    Rails.logger.info("purged #{count} job(s)")
  end
end
