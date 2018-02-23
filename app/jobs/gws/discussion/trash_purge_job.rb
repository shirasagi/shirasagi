class Gws::Discussion::TrashPurgeJob < Gws::ApplicationJob
  include Gws::TrashPurge::BaseJob

  self.model = Gws::Discussion::Forum

  private

  def set_items
    @items = model.site(site).forum.only_deleted(@threshold)
  end
end
