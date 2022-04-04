class Cms::Node::GenerateJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  queue_as { segment.presence || :default }

  self.task_class = Cms::Task
  self.task_name = "cms:generate_nodes"
  self.controller = Cms::Agents::Tasks::NodesController
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
