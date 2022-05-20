class Cms::Line::TestDeliverJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:line_test_deliver"
  self.controller = Cms::Agents::Tasks::Line::MessagesController
  self.action = :test_deliver

  def perform(message_id, test_member_ids)
    message = Cms::Line::Message.site(site).where(id: message_id).first
    test_members = Cms::Line::TestMember.site(site).in(id: test_member_ids).to_a
    task.process self.class.controller, self.class.action, { site: site, user: user, message: message, test_members: test_members }
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond
  end
end
