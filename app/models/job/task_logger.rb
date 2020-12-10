require 'logger'

class Job::TaskLogger < ::Logger
  extend Forwardable

  FLUSH_INTERVAL = 10.seconds

  private_class_method :new

  def initialize
    if Fs.mode == :grid_fs
      @device = TaskLogDevice.new
    else
      @device = WrapLogDevice.new
    end
    super(@device)
  end

  def_delegators(:@device, :attach, :detach)

  class << self
    def attach(loggable)
      @@task_logger ||= begin
        logger = new
        logger.level = ::Job::Service.config.log_level || Rails.logger.level
        logger.formatter = Rails.logger.formatter
        Rails.logger.extend ActiveSupport::Logger.broadcast(logger)
        logger
      end

      @@task_logger.attach(loggable)
    end

    def detach(_)
      return unless @@task_logger
      @@task_logger.detach
    end
  end

  class TaskLogDevice
    attr_accessor :loggable

    def attach(loggable)
      save = detach
      @loggable = loggable
      save
    end

    def detach
      save = @loggable
      @loggable = nil

      save.save if save
      save
    end

    def write(message)
      if @loggable
        @loggable.logs << message
        elapsed = Time.zone.now - @loggable.updated
        @loggable.save if elapsed > FLUSH_INTERVAL
      end
    end

    # do not remove close method
    def close
    end
  end

  class WrapLogDevice
    attr_accessor :loggable

    def attach(loggable)
      save = detach
      @loggable = loggable
      @file = open_logfile(loggable.file_path)
      save
    end

    def detach
      save = @loggable
      @loggable = nil

      if @file
        @file.close
      end
      @file = nil

      save
    end

    def write(message)
      if @file
        @file.puts(message)
      end
    end

    # do not remove close method
    def close
    end

    private

    def open_logfile(filename)
      dirname = ::File.dirname(filename)
      ::FileUtils.mkdir_p(dirname) unless ::Dir.exists?(dirname)

      file = ::File.open(filename, 'a')
      file.sync = true
      file
    end
  end
end
