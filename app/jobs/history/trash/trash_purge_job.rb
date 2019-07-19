class History::Trash::TrashPurgeJob < SS::ApplicationJob
  def perform(*_)
    criteria = History::Trash.all
    criteria = criteria.site(site) if site.present?
    count = criteria.destroy_all
    Rails.logger.info "#{I18n.l(@threshold.to_date)}以前の#{model.model_name.human}を#{count}件削除しました。"
  end
end
