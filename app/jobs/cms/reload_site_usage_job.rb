class Cms::ReloadSiteUsageJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:site_usage"

  def perform
    site.reload_usage!
  end
end
