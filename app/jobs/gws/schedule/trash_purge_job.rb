class Gws::Schedule::TrashPurgeJob < Gws::ApplicationJob
  include SS::TrashPurge::BaseJob

  self.model = Gws::Schedule::Plan
end
