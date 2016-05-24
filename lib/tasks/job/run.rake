namespace :job do
  task :setup_logger => [:environment] do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.level = Logger::DEBUG
  end

  task :run => [:environment, :setup_logger] do
    install_signal_handlers
    Job::Service.run(ENV["config"])
  end

  def install_signal_handlers
    [:INT, :TERM].each do |signal|
      Signal.trap(signal) { handle_signal(signal) }
    end
  end

  def handle_signal(_)
    Thread.new do
      Job::Service.shutdown
    end
  end
end
