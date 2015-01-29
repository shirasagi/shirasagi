namespace :job do
  task :setup_logger => [:environment] do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::DEBUG
  end

  task :run => [:environment, :setup_logger] do
    config = ENV["config"]
    unless config.blank?
      config = SS.config.job[config]
    end
    Job::MasterService.run config
  end
end
