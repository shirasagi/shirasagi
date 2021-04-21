module Tasks
  class Job
    class << self
      def run
        setup_logger
        install_signal_handlers
        ::Job::Service.run(ENV["config"])
      end

      private

      def setup_logger
        Rails.logger ||= begin
          logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
          logger.level = Logger::DEBUG
          logger
        end
      end

      def install_signal_handlers
        [:INT, :TERM].each do |signal|
          Signal.trap(signal) { handle_signal(signal) }
        end
      end

      def handle_signal(_signal)
        Thread.new do
          ::Job::Service.shutdown
        end
      end
    end
  end
end
