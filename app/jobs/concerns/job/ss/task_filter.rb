module Job::SS::TaskFilter
  extend ActiveSupport::Concern

  included do
    mattr_accessor(:task_class, instance_accessor: false) { SS::Task }
    mattr_accessor(:task_name, instance_accessor: false)
    mattr_accessor(:controller, instance_accessor: false)
    mattr_accessor(:action, instance_accessor: false)
    attr_accessor :task
    around_perform :ready
  end

  private
    def task_cond
      cond = { name: self.class.task_name }
      cond[:site_id] = site_id
      cond
    end

    def ready
      @task = self.class.task_class.order_by(id: 1).find_or_create_by(task_cond)
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
