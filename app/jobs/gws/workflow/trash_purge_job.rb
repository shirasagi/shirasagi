class Gws::Workflow::TrashPurgeJob < Gws::ApplicationJob
  include Gws::TrashPurge::BaseJob

  self.model = Gws::Workflow::File
end
