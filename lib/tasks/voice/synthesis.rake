namespace :voice do
  task :setup_logger => [:environment] do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::DEBUG
  end

  task :synthesis => [:environment, :setup_logger] do
    id_or_url = ENV["id"] || ENV["url"]
    force = ENV["force"] ||  "false"
    force = force =~ /^(false|0)$/i ? false : true

    if id_or_url.blank?
      Rails.logger.error("url parameter is not given")
    else
      Voice::SynthesisJob.new.call id_or_url, force
    end
  end
end
