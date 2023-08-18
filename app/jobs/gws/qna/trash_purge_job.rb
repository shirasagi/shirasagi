class Gws::Qna::TrashPurgeJob < Gws::ApplicationJob
  include Gws::TrashPurge::BaseJob

  self.model = Gws::Qna::Topic

  private

  def set_items
    @items = model.site(site).topic.only_deleted(@threshold)
  end
end
