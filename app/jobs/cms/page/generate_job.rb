class Cms::Page::GenerateJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:generate_pages"
  self.controller = Cms::Agents::Tasks::PagesController
  self.action = :generate

  def generate_key
    arguments.dig(0, :generate_key)
  end

  def task_name
    generate_key.present? ? "#{self.class.task_name} key=#{generate_key}" : self.class.task_name
  end
end
