require 'benchmark'
require 'English'

class Job::Service
  extend SS::Translation
  include SS::Document
  include SS::Task::Model

  attr_accessor :config

  DEFAULT_LOG_LEVEL = Logger::INFO

  class << self
    public
      def run(config = nil)
        config ||= SS.config.job.default
        with_lock(config) do |service|
          service.config = config
          service.run
        end
      end

    private
      def with_lock(config)
        model = config['model']
        num_workers = config["num_workers"]
        service = acquire_lock(model, num_workers == 0 ? 1 : num_workers)
        return unless service

        begin
          return yield service
        ensure
          release_lock(model)
        end
      end

      def acquire_lock(name, limits)
        # ensure that service is existed.
        service_id = Job::Service.find_or_create_by(name: name).id

        # increment atomically
        criteria = Job::Service.where(id: service_id)
        service = criteria.find_and_modify({ '$inc' => { current_count: 1 } }, new: true)
        if service.current_count > limits
          # already started a service
          Rails.logger.debug("already started a service")
          release_lock(name)
          return nil
        end

        if service.current_count == 1
          service.state = "running"
          service.started = Time.now
          service.save
        end

        service
      end

      def release_lock(name)
        service_id = Job::Service.find_or_create_by(name: name).id

        # decrement atomically
        criteria = Job::Service.where(id: service_id)
        criteria = criteria.gt(current_count: 0)
        service = criteria.find_and_modify({ '$inc' => { current_count: -1, total_count: 1 }}, new: true)
        if service && service.current_count == 0
          service.state = "stop"
          service.closed = Time.now
          service.save
        end
        service
      end
  end

  public
    def run
      open_logger
      begin
        execute_loop
      ensure
        close_logger
      end
    end

  private
    def execute_loop
      with_task do |task, job_log|
        begin
          Rails.logger.info("Started Job #{task.id}")
          job_log.state = "running"
          job_log.started = Time.now
          job_log.save

          time = Benchmark.realtime do
            job = create_job(task)
            job.call *(task.args)
          end

          job_log.state = "completed"
          job_log.closed = Time.now
          Rails.logger.info("Completed Job #{task.id} in #{time * 1000} ms")
        rescue Exception => e
          job_log.state = "failed"
          job_log.closed = Time.now
          Rails.logger.fatal("Failed Job #{task.id}: #{e.class} (#{e.message}):\n  #{e.backtrace[0..5].join('\n  ')}")
        end
      end
    end

    def create_job(task)
      return task.class_name.constantize.new
    end

    def open_logger
      unless config["log_file"].blank?
        @logger = ::Logger.new(File.expand_path(config["log_file"], Rails.root))
        @logger.level = log_level
        Rails.logger.extend(ActiveSupport::Logger.broadcast(@logger))
      end
    end

    def close_logger
      @logger.close if @logger
    end

    def dequeue_task
      config["poll"].each do |queue_name|
        task = Job::Model.dequeue(queue_name)
        return task if task
      end

      nil
    end

    def with_task
      loop do
        task = dequeue_task
        break unless task

        begin
          with_job_log task do |job_log|
            yield task, job_log
          end
        ensure
          task.delete
        end
      end

      nil
    end

    def with_job_log(task)
      job_log = Job::Log.add(task)
      begin
        with_task_logger job_log do
          yield job_log
        end
      ensure
        job_log.save
      end
    end

    def with_task_logger(task)
      unless @task_logger
        @task_logger = Job::TaskLogger.new
        @task_logger.level = log_level
        Rails.logger.extend ActiveSupport::Logger.broadcast(@task_logger)
      end
      @task_logger.task = task

      begin
        return yield task
      ensure
        @task_logger.task = nil
      end
    end

    def log_level
      case config["log_level"]
      when /fatal/i then
        Logger::FATAL
      when /error/i then
        Logger::ERROR
      when /warn/i then
        Logger::WARN
      when /info/i then
        Logger::INFO
      when /debug/i then
        Logger::DEBUG
      else
        DEFAULT_LOG_LEVEL
      end
    end
end
