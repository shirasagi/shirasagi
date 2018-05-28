class Cms::Page::TrashPurgeJob < Gws::ApplicationJob
  include SS::TrashPurge::BaseJob

  self.model = Cms::Page
end
