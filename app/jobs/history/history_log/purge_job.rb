class History::HistoryLog::PurgeJob < Cms::ApplicationJob
  include SS::TrashPurge::BaseJob

  self.model = History::Log

  private

  def set_items
    @items = model.lt(created: @threshold)
    @items = @items.site(site) if site.present?
    @items
  end
end
