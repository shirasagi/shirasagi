module SS
  module LogSupport
    class StdoutLogger
      FORMAT = "%5s -- %s: %s".freeze
      SEV_LABEL = %w(DEBUG INFO WARN ERROR FATAL ANY).each(&:freeze).freeze

      def enable
        @enabled = true
      end

      def disable
        @enabled = false
      end

      def add(*args, &block)
        if @enabled
          severity, message, progname = *args
          severity ||= ::Logger::Severity::UNKNOWN
          if message.nil?
            if block_given?
              message = yield
            else
              message = progname
              progname = nil
            end
          end
          puts format_message(severity, message, progname)
        end
      end

      def format_message(severity, message, progname)
        format(FORMAT, SEV_LABEL[severity], message, progname)
      end
    end

    mattr_accessor :stdout_logger

    def puts_log_stdout(enables)
      if enables
        SS::LogSupport.stdout_logger.enable
      else
        SS::LogSupport.stdout_logger.disable
      end
    end

    module_function

    def install_stdout_logger
      SS::LogSupport.stdout_logger ||= begin
        logger = StdoutLogger.new
        Rails.logger.extend ActiveSupport::Logger.broadcast(logger)
        logger
      end
    end
  end
end

RSpec.configuration.include(SS::LogSupport)

RSpec.configuration.before(:suite) do
  SS::LogSupport.install_stdout_logger
end
