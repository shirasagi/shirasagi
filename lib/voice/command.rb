class Voice::Command
  class << self
    public
      def run_with_logging(cmd, prompt)
        require "open3"
        Rails.logger.debug("popen3: #{cmd}")
        stdout, stderr, status = Open3.capture3(cmd)
        Rails.logger.debug("[#{prompt} stdout] #{stdout}") if stdout.present?
        Rails.logger.info("[#{prompt} stderr] #{stderr}") if stderr.present?
        status
      end
  end
end
