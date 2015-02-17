class SS::RakeRunner
  NULL_DEVICE = "/dev/null"

  class << self
    private
      def do_spawn(task, *args)
        cmd = "bundle exec rake #{task} #{args.join(" ")}"
        Rails.logger.debug "spawn: #{cmd}"
        spawn(cmd, in: NULL_DEVICE, out: NULL_DEVICE, err: NULL_DEVICE)
      end

    public
      def run_async(task, *args)
        pid = do_spawn(task, *args)
        Process.detach(pid)
      end

      def run(task, *args)
        pid = do_spawn(task, *args)
        _, status = Process.waitpid2(pid)
        status
      end
  end
end
