module Job::SS::Binding::Task
  extend ActiveSupport::Concern

  included do
    # task class
    mattr_accessor(:task_class, instance_accessor: false) { SS::Task }
    # task
    attr_accessor :task_id

    around_perform :ready
  end

  def task
    @task ||= begin
      return nil if task_id.blank?
      self.class.task_class.where({ id: task_id }).first
    end
  end

  def bind(bindings)
    if bindings['task_id'].present?
      self.task_id = bindings['task_id'].to_param
      @task = nil
    end
    super
  end

  def bindings
    ret = super
    ret['task_id'] = task_id if task_id.present?
    ret
  end

  private

  def ready
    if task.blank?
      return yield
    end

    unless task.start
      Rails.logger.info("task #{task.name} is already started")
      return
    end

    ret = nil
    begin
      require 'benchmark'
      time = Benchmark.realtime { ret = yield }
      task.log sprintf("# %d sec\n\n", time)
    rescue Interrupt => e
      task.log "-- #{e}"
      #@task.log e.backtrace.join("\n")
    rescue StandardError => e
      task.log "-- Error"
      task.log e.to_s
      task.log e.backtrace.join("\n")
    ensure
      task.close
    end
    ret
  end
end
