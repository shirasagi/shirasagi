class Gws::Circular::TrashPurgeJob < Gws::ApplicationJob
  include SS::TrashPurge::BaseJob

  self.model = Gws::Circular::Post
end
