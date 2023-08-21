class Gws::Schedule::TrashPurgeJob < Gws::ApplicationJob
  include Gws::TrashPurge::BaseJob

  self.model = Gws::Schedule::Plan
end
