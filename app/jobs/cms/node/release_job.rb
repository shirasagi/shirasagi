class Cms::Node::ReleaseJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  self.task_name = "cms:release_nodes"
  self.controller = Cms::Agents::Tasks::NodesController
  self.action = :release
end
