@config = Job::Service::Config.new
@config.mode = "service"
@config.polling.queues = ["transaction"]
