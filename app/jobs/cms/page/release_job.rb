class Cms::Page::ReleaseJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:release_pages"
  self.controller = Cms::Agents::Tasks::PagesController
  self.action = :release
end
