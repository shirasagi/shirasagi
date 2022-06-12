class Cms::FormDb::ImportUrlsJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::FormDb::ImportTask
  self.task_name = "cms:form_db:import_urls"
  self.controller = Cms::Agents::Tasks::FormDb::ImportController
  self.action = :import_urls

  def perform(opts = {})
    task.process self.class.controller, self.class.action, opts.merge(site: site)
  end

  private

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond
  end
end
