class Cms::Node::TrashPurgeJob < Gws::ApplicationJob
  include SS::TrashPurge::BaseJob

  self.model = Cms::Node
end
