class Cms::Line::DeliverJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:line_deliver"
  self.controller = Cms::Agents::Tasks::Line::MessagesController
  self.action = :deliver

  def perform(message_id)
    message = Cms::Line::Message.site(site).where(id: message_id).first
    task.process self.class.controller, self.class.action, { site: site, user: user, message: message }
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond
  end
end
