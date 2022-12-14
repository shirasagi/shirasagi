module SS
  module LogSupport
    class StdoutLogger
      FORMAT = "%5s -- %s: %s".freeze
      SEV_LABEL = %w(DEBUG INFO WARN ERROR FATAL ANY).each(&:freeze).freeze

      def enable
        @enabled = true
        tmp_file_path = "#{SS::TmpDir.tmpdir}/#{unique_id}.log"
        @tmp_file = ::File.open(tmp_file_path, "w+")
      end

      def disable(puts_to_console)
        @enabled = false
        if @tmp_file
          if puts_to_console
            @tmp_file.rewind
            IO.copy_stream(@tmp_file, $stdout)
          end

          @tmp_file.close rescue nil
        end

        @tmp_file = nil
      end

      def add(*args, &block)
        if @enabled && @tmp_file
          severity, message, progname = *args
          severity ||= ::Logger::Severity::UNKNOWN
          if message.nil?
            if block
              message = yield
            else
              message = progname
              progname = nil
            end
          end
          @tmp_file.puts format_message(severity, message, progname)
        end
      end

      def format_message(severity, message, progname)
        format(FORMAT, SEV_LABEL[severity], message, progname)
      end
    end

    mattr_accessor :stdout_logger

    def self.extended(obj)
      js = obj.metadata[:js]

      obj.before do
        if js && ENV.fetch('logs_on_failure', '1') == '1'
          SS::LogSupport.stdout_logger.enable
        end
      end

      obj.after do
        if js && ENV.fetch('logs_on_failure', '1') == '1'
          SS::LogSupport.stdout_logger.disable(RSpec.current_example.display_exception.present?)
        end
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

RSpec.configuration.extend(SS::LogSupport)
RSpec.configuration.before(:suite) do
  SS::LogSupport.install_stdout_logger
end
