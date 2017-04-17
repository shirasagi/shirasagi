require 'logger'

class Job::TaskLogger < ::Logger
  extend Forwardable

  FLUSH_INTERVAL = 10.seconds

  private_class_method :new

  def initialize
    @device = TaskLogDevice.new
    super(@device)
  end

  def_delegators(:@device, :loggable, :loggable=)

  class << self
    def attach(loggable)
      @@task_logger ||= begin
        logger = new
        logger.level = ::Job::Service.config.log_level || Rails.logger.level
        Rails.logger.extend ActiveSupport::Logger.broadcast(logger)
        logger
      end

      save = @@task_logger.loggable
      @@task_logger.loggable = loggable
      save
    end

    def detach(_)
      return unless @@task_logger
      @@task_logger.loggable = nil
    end
  end

  class TaskLogDevice
    attr_accessor :loggable

    def write(message)
      if loggable
        loggable.logs << message.chomp
        elapsed = Time.zone.now - loggable.updated
        loggable.save if elapsed > FLUSH_INTERVAL
      end
    end

    # do not remove close method
    def close
    end
  end
end
