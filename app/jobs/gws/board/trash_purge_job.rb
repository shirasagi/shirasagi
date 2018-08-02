class Gws::Board::TrashPurgeJob < Gws::ApplicationJob
  include SS::TrashPurge::BaseJob

  self.model = Gws::Board::Topic

  private

  def set_items
    @items = model.site(site).topic.only_deleted(@threshold)
  end
end
