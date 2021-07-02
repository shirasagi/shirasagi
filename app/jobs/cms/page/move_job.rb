class Cms::Page::MoveJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:move_pages"
  self.controller = Cms::Agents::Tasks::PagesController
  self.action = :move

  def perform(opts = {})
    task.process self.class.controller, self.class.action, opts.merge(site: site, node: node, user: user)
  end
end
