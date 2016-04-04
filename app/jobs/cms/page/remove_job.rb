class Cms::Page::RemoveJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:remove_pages"
  self.controller = Cms::Agents::Tasks::PagesController
  self.action = :remove
end
