class Job::TaskLogger < Logger
  class << self
    def attach(job_log)
      new_logger = new(job_log)
      old_loggers = Rails.logger.broadcasts.select { |logger| logger.is_a?(Job::TaskLogger) }
      old_loggers.each { |logger| Rails.logger.stop_broadcasting_to(logger) }
      Rails.logger.broadcast_to(new_logger)

      old_loggers.each(&:close)
      old_loggers[0].try(:job_log)
    end

    def detach(*_args)
      loggers = Rails.logger.broadcasts.select { |logger| logger.is_a?(Job::TaskLogger) }
      loggers.each { |logger| Rails.logger.stop_broadcasting_to(logger) }
      loggers.each(&:close)
      loggers[0].try(:job_log)
    end
  end

  def initialize(job_log)
    file = open_logfile(job_log.file_path)

    @job_log = job_log
    super(file, formatter: Rails.logger.formatter, level: ::Job::Service.config.log_level || Rails.logger.level)
  end

  attr_reader :job_log

  private

  def open_logfile(filename)
    dirname = ::File.dirname(filename)
    ::FileUtils.mkdir_p(dirname) unless ::Dir.exist?(dirname)

    file = ::File.open(filename, 'a')
    file.sync = true
    file
  end
end
