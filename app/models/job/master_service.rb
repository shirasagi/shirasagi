require 'English'

class Job::MasterService
  class << self
    public
      def run(config = nil)
        config ||= SS.config.job.default
        num_workers = config["num_workers"]

        if num_workers == 0
          # execute jobs in-place
          Job::Service.run config
          return true
        end

        # execute jobs in external process
        start_slave_in_external_process(config)
        true
      end

    private
      def start_slave_in_external_process(config)
        name = config['name']
        num_workers = config["num_workers"]

        cmd = "bundle exec rake job:worker RAILS_ENV=#{Rails.env}"
        cmd = "#{cmd} config=#{name}" unless name.blank?
        threads = []
        num_workers.times do
          threads << Thread.new do
            Thread.pass
            Rails.logger.debug("system(#{cmd})")
            system(cmd)
          end
        end

        threads.each do |t|
          t.join rescue nil
        end
      end
  end
end
