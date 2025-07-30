class SS::RakeRunner
  class << self
    def run_async(task, *args)
      Rails.logger.debug "spawn: bundle exec rake #{task} #{args.join(" ")}"
      SS::Command.run_async("bundle", "exec", "rake", task, *args)
    end

    def run(task, *args)
      Rails.logger.debug "spawn: bundle exec rake #{task} #{args.join(" ")}"
      SS::Command.run("bundle", "exec", "rake", task, *args)
    end
  end
end
