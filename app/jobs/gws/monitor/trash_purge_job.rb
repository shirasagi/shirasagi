class Gws::Monitor::TrashPurgeJob < Gws::ApplicationJob
  include Gws::TrashPurge::BaseJob

  self.model = Gws::Monitor::Topic

  private

  def set_items
    @items = model.site(site).topic.only_deleted(@threshold)
  end
end
