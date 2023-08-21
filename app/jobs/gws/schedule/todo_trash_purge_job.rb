class Gws::Schedule::TodoTrashPurgeJob < Gws::ApplicationJob
  include Gws::TrashPurge::BaseJob

  self.model = Gws::Schedule::Todo
end
