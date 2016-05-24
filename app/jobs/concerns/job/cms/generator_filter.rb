module Job::Cms::GeneratorFilter
  extend ActiveSupport::Concern

  included do
    mattr_accessor(:task_name, instance_accessor: false)
    mattr_accessor(:controller, instance_accessor: false)
    mattr_accessor(:action, instance_accessor: false)
  end

  def perform(opts = {})
    ready name: self.class.task_name, site_id: site_id, node_id: node_id do |task|
      task.process self.class.controller, self.class.action, opts.merge(site: site, node: node)
    end
  end

  private

    def ready(cond, &block)
      task = Cms::Task.find_or_create_by(cond)
      unless task.start
        Rails.logger.info("taks #{task.name} is already started")
        return false
      end

      begin
        require 'benchmark'
        time = Benchmark.realtime { yield task }
        task.log sprintf("# %d sec\n\n", time)
      rescue Interrupt => e
        task.log "-- #{e}"
        #task.log e.backtrace.join("\n")
      rescue StandardError => e
        task.log "-- Error"
        task.log e.to_s
        task.log e.backtrace.join("\n")
      end
      task.close
    end
end
