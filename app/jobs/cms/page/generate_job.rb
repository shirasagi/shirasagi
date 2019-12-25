class Cms::Page::GenerateJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:generate_pages"
  self.controller = Cms::Agents::Tasks::PagesController
  self.action = :generate

  def generate_key
    arguments.dig(0, :generate_key)
  end
end
