module SS
  module LogSupport
    # class StdoutLogger
    #   FORMAT = "%5s -- %s: %s".freeze
    #   SEV_LABEL = %w(DEBUG INFO WARN ERROR FATAL ANY).each(&:freeze).freeze
    #
    #   def enable
    #     @enabled = true
    #     tmp_file_path = "#{SS::TmpDir.tmpdir}/#{unique_id}.log"
    #     @tmp_file = ::File.open(tmp_file_path, "w+")
    #   end
    #
    #   def disable(puts_to_console)
    #     @enabled = false
    #     if @tmp_file
    #       if puts_to_console
    #         @tmp_file.rewind
    #         IO.copy_stream(@tmp_file, $stdout)
    #       end
    #
    #       @tmp_file.close rescue nil
    #     end
    #
    #     @tmp_file = nil
    #   end
    #
    #   def add(severity, message, progname, &block)
    #     if @enabled && @tmp_file
    #       severity ||= ::Logger::Severity::UNKNOWN
    #       if message.nil?
    #         if block
    #           message = yield
    #         else
    #           message = progname
    #           progname = nil
    #         end
    #       end
    #       @tmp_file.puts format_message(severity, message, progname)
    #     end
    #   end
    #   alias log add
    #
    #   def debug(progname = nil, &block)
    #     add(::Logger::DEBUG, nil, progname, &block)
    #   end
    #
    #   def info(progname = nil, &block)
    #     add(::Logger::INFO, nil, progname, &block)
    #   end
    #
    #   def warn(progname = nil, &block)
    #     add(::Logger::WARN, nil, progname, &block)
    #   end
    #
    #   def error(progname = nil, &block)
    #     add(::Logger::ERROR, nil, progname, &block)
    #   end
    #
    #   def fatal(progname = nil, &block)
    #     add(::Logger::FATAL, nil, progname, &block)
    #   end
    #
    #   def unknown(progname = nil, &block)
    #     add(::Logger::UNKNOWN, nil, progname, &block)
    #   end
    #
    #   private
    #
    #   def format_message(severity, message, progname)
    #     format(FORMAT, SEV_LABEL[severity], message, progname)
    #   end
    # end

    FORMAT = "%5s -- %s: %s".freeze

    mattr_accessor :logger, :log_file_path

    def self.formatter
      @formatter ||= begin
        proc do |severity, _time, progname, msg|
          format(FORMAT, severity, progname, msg)
        end
      end
    end

    def self.enable
      return if SS::LogSupport.logger

      tmp_file_path = "#{SS::TmpDir.tmpdir}/#{unique_id}.log"
      SS::LogSupport.logger = ::Logger.new(tmp_file_path, formatter: SS::LogSupport.formatter)
      SS::LogSupport.log_file_path = tmp_file_path
      Rails.logger.broadcast_to(SS::LogSupport.logger)
      true
    end

    def self.disable(puts_to_console)
      return unless SS::LogSupport.logger

      logger = SS::LogSupport.logger
      log_file_path = SS::LogSupport.log_file_path
      SS::LogSupport.logger = nil
      SS::LogSupport.log_file_path = nil

      Rails.logger.stop_broadcasting_to(logger)
      logger.close

      IO.copy_stream(log_file_path, $stdout) if puts_to_console && ::File.exist?(log_file_path)
      ::FileUtils.rm_f(log_file_path)

      true
    end

    def self.extended(obj)
      js = obj.metadata[:js]

      obj.before do
        if js && ENV.fetch('logs_on_failure', '1') == '1'
          SS::LogSupport.enable
        end
      end

      obj.after do
        if js && ENV.fetch('logs_on_failure', '1') == '1'
          SS::LogSupport.disable(RSpec.current_example.display_exception.present?)
        end
      end
    end
  end
end

RSpec.configuration.extend(SS::LogSupport)
