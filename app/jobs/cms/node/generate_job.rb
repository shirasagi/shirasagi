class Cms::Node::GenerateJob < Cms::ApplicationJob
include Job::Cms::GeneratorFilter

  self.task_name = "cms:generate_nodes"
  self.controller = Cms::Agents::Tasks::NodesController
  self.action = :generate
end
