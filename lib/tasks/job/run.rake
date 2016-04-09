namespace :job do
  task :setup_logger => [:environment] do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::DEBUG
  end

  task :run => [:environment, :setup_logger] do
    Job::Service.run(ENV["config"])
  end
end
