class Cms::ConsistencyCheckJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:consistency_check"

  def perform(*args)
    options = args.extract_options!
    @repair = options.fetch(:repair, false)
  end
end
