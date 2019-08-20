class Event::Page::ImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "event:import_pages"
  self.controller = Event::Agents::Tasks::Page::PagesController
  self.action = :import_csv

  def perform(ss_file_id)
    file = SS::File.find(ss_file_id)
    task.process self.class.controller, self.class.action, { site: site, node: node, user: user, file: file }
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:node_id] = node_id
    cond
  end
end
