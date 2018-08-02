class Gws::Schedule::TodoTrashPurgeJob < Gws::ApplicationJob
  include SS::TrashPurge::BaseJob

  self.model = Gws::Schedule::Todo
end
