class Cms::Page::UpdateJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:update_pages"
  self.controller = Cms::Agents::Tasks::PagesController
  self.action = :update
end
