class Cms::Line::DeliverReservedJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:line_reserve_deliver"
  self.controller = Cms::Agents::Tasks::Line::MessagesController
  self.action = :reserve_deliver

  def perform
    task.process self.class.controller, self.class.action, { site: site, user: user }
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond
  end
end
