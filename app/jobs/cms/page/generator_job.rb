class Cms::Page::GeneratorJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:generate_pages"
  self.controller = Cms::Agents::Tasks::PagesController
  self.action = :generate
end
