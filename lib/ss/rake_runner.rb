class SS::RakeRunner
  NULL_DEVICE = "/dev/null"

  class << self
    def run_async(task, *args)
      pid = do_spawn(task, *args)
      Process.detach(pid)
    end

    def run(task, *args)
      pid = do_spawn(task, *args)
      _, status = Process.waitpid2(pid)
      status
    end

    private
      def do_spawn(task, *args)
        Rails.logger.debug "spawn: bundle exec rake #{task} #{args.join(" ")}"
        spawn({}, "bundle", "exec", "rake", task, *args, { in: NULL_DEVICE, out: NULL_DEVICE, err: NULL_DEVICE })
      end
  end
end
