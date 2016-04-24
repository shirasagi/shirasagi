class Job::Service
  extend SS::Translation
  include SS::Document
  include SS::Model::Task

  class << self
    def config
      @config ||= Job::Service::Config.new
    end

    def configure(section = 'default')
      @config = Job::Service::Config.new(section)
      yield config
    end

    def run(config = nil)
      load_config(config) if config

      @runner = Job::Service::Runner.new
      @runner.run
      @runner = nil
    end

    def shutdown
      @runner.shutdown if @runner
    end

    def acquire_lock(name, limits = 1)
      # ensure that service is existed.
      service_id = Job::Service.find_or_create_by(name: name).id

      # increment atomically
      criteria = Job::Service.where(id: service_id)
      service = criteria.find_one_and_update({ '$inc' => { current_count: 1 } }, return_document: :after)
      if service.current_count > limits
        # already started a service
        Rails.logger.info("already started a job service")
        release_lock(name)
        return nil
      end

      if service.current_count == 1
        service.state = "running"
        service.started = Time.zone.now
        service.save
      end

      service
    end

    def release_lock(name)
      service_id = Job::Service.find_or_create_by(name: name).id

      # decrement atomically
      criteria = Job::Service.where(id: service_id)
      criteria = criteria.gt(current_count: 0)
      service = criteria.find_one_and_update({ '$inc' => { current_count: -1, total_count: 1 }}, return_document: :after)
      if service && service.current_count == 0
        service.state = "stop"
        service.closed = Time.zone.now
        service.save
      end
      service
    end

    private

    def load_config(config)
      if File.exist?(config)
        class_eval(File.read(config), config, 1)
      else
        @config = Job::Service::Config.new(config)
      end
    end
  end
end
