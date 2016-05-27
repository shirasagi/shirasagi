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
        logger.level = translate_severity(::Job::Service.config.log_level) || Rails.logger.level
        Rails.logger.extend ActiveSupport::Logger.broadcast(logger)
        logger
      end

      @@task_logger.loggable = loggable
    end

    def detach(_)
      return unless @@task_logger
      @@task_logger.loggable = nil
    end

    def translate_severity(severity)
      return severity if severity.is_a?(Integer)

      _severity = severity.to_s.downcase
      case _severity
      when 'debug'.freeze
        ::Logger::DEBUG
      when 'info'.freeze
        ::Logger::INFO
      when 'warn'.freeze
        ::Logger::WARN
      when 'error'.freeze
        ::Logger::ERROR
      when 'fatal'.freeze
        ::Logger::FATAL
      when 'unknown'.freeze
        ::Logger::UNKNOWN
      else
        raise ArgumentError, "invalid log level: #{severity}"
      end
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
