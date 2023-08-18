class Cms::ImportFilesJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:import_files"
  self.controller = Cms::Agents::Tasks::ImportFilesController
  self.action = :import

  def perform(opts = {})
    task.process self.class.controller, self.class.action, { site: site, node: node, user: user }
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:node_id] = node_id
    cond
  end
end
