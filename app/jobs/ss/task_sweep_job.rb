class SS::TaskSweepJob < SS::ApplicationJob
  include SS::SweepBase

  def model
    SS::Task
  end

  def keep_duration
    SS.config.ss.keep_tasks
  end
end
