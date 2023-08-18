class Cms::FormDb::ImportUrlJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::FormDb::ImportTask
  self.task_name = "cms:form_db:import_url"
  self.controller = Cms::Agents::Tasks::FormDb::ImportController
  self.action = :import_url

  def perform(opts = {})
    task.process self.class.controller, self.class.action, opts.merge(site: site, node: node)
  end

  private

  def task_cond
    args = arguments[0].with_indifferent_access

    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:db_id] = args[:db_id]
    cond
  end
end
