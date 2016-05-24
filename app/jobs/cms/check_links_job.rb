class Cms::CheckLinksJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:check_links"
  self.controller = Cms::Agents::Tasks::LinksController
  self.action = :check
end
