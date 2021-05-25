class MongoAccessCounter
  class << self
    attr_reader :started_count, :succeeded_count, :failed_count

    def add_started_count
      @started_count += 1
    end

    def add_succeeded_count
      @succeeded_count += 1
    end

    def add_failed_count
      @failed_count += 1
    end

    def reset_count
      @started_count = @succeeded_count = @failed_count = 0
    end

    def install_mongo_subscriber
      # already subscribed
      return if @subscriber

      reset_count
      @subscriber = Class.new do
        def started(_event)
          MongoAccessCounter.add_started_count
        end

        def succeeded(_event)
          MongoAccessCounter.add_succeeded_count
        end

        def failed(_event)
          MongoAccessCounter.add_failed_count
        end
      end.new

      Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, @subscriber)
      Mongoid::Clients.clients.each { |_key, client| client.subscribe(Mongo::Monitoring::COMMAND, @subscriber) }
    end
  end
end

RSpec.configuration.before(:suite) do
  MongoAccessCounter.install_mongo_subscriber
end
