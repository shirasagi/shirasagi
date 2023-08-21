require 'benchmark'

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
    return yield if task.blank?

    task.run_with(rejected: method(:start_rejected)) do
      ret = nil
      time = Benchmark.realtime { ret = yield }
      task.log sprintf("# %d sec\n\n", time)
      ret
    end
  end

  def start_rejected
    Rails.logger.info("task #{task.name} is already started")
  end
end
