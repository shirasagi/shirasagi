class Gws::SharedAddress::TrashPurgeJob < Gws::ApplicationJob
  include SS::TrashPurge::BaseJob

  self.model = Gws::SharedAddress::Address
end
