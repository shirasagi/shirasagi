class Gws::Report::TrashPurgeJob < Gws::ApplicationJob
  include SS::TrashPurge::BaseJob

  self.model = Gws::Report::File
end
