class Gws::SharedAddress::TrashPurgeJob < Gws::ApplicationJob
  include Gws::TrashPurge::BaseJob

  self.model = Gws::SharedAddress::Address
end
