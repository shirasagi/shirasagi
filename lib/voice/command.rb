class Voice::Command
  class << self
    public
      def run_with_logging(cmd, prompt)
        require "open3"
        Rails.logger.debug("popen3: #{cmd}")
        Open3.popen3(cmd) do |i, o, e, t|
          Thread.new do
            o.each_line do |line|
              Rails.logger.debug("[#{prompt}] #{line}")
            end
          end
          Thread.new do
            e.each_line do |line|
              Rails.logger.info("[#{prompt}] #{line}")
            end
          end
          i.write ''
          i.close
          t.join
          t.value
        end
      end
  end
end
