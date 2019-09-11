class History::Trash::TrashPurgeJob < Cms::ApplicationJob
  include Gws::TrashPurge::BaseJob

  self.model = History::Trash

  def perform(*_)
    count = @items.destroy_all
    Rails.logger.info "#{I18n.l(@threshold.to_date)}以前の#{model.model_name.human}を#{count}件削除しました。"
  end

  private

  def set_items
    @items = model.lt(created: @threshold)
    @items = @items.site(site) if site.present?
    @items
  end
end
