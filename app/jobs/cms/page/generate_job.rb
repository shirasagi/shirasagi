class Cms::Page::GenerateJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  queue_as { segment.presence || :default }

  self.task_class = Cms::Task
  self.task_name = "cms:generate_pages"
  self.controller = Cms::Agents::Tasks::PagesController
  self.action = :generate

  def segment
    arguments.dig(0, :segment)
  end

  def task_cond
    cond = super
    cond[:segment] = segment
    cond
  end
end
