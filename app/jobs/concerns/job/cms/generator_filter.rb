module Job::Cms::GeneratorFilter
  extend ActiveSupport::Concern

  included do
    mattr_accessor(:task_class, instance_accessor: false) { Cms::Task }
    mattr_accessor(:task_name, instance_accessor: false)
    mattr_accessor(:controller, instance_accessor: false)
    mattr_accessor(:action, instance_accessor: false)
    attr_accessor :task
    around_perform :ready
  end

  def perform(opts = {})
    task.process self.class.controller, self.class.action, opts.merge(site: site, node: node)
  end

  private
    def ready
      cond = { name: self.class.task_name }
      cond[:site_id] = site_id if site_id.present?
      cond[:node_id] = node_id if node_id.present?
      @task = self.class.task_class.find_or_create_by(cond)
      unless @task.start
        Rails.logger.info("task #{@task.name} is already started")
        return
      end

      ret = nil
      begin
        require 'benchmark'
        time = Benchmark.realtime { ret = yield }
        @task.log sprintf("# %d sec\n\n", time)
      rescue Interrupt => e
        @task.log "-- #{e}"
        #@task.log e.backtrace.join("\n")
      rescue StandardError => e
        @task.log "-- Error"
        @task.log e.to_s
        @task.log e.backtrace.join("\n")
      ensure
        @task.close
      end
      ret
    end
end
