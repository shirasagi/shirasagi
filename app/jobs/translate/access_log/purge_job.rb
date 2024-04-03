class Translate::AccessLog::PurgeJob < Cms::ApplicationJob

  DEFAULT_THRESHOLD_DAYS = 60

  before_perform :set_items

  def model
    Translate::AccessLog
  end

  def perform
    count = @items.destroy_all
    Rails.logger.info "#{I18n.l(@threshold.to_date)}以前の#{model.model_name.human}を#{count}件削除しました。"
  end

  def set_items
    @threshold = Time.zone.now - (site.translate_access_log_threshold || DEFAULT_THRESHOLD_DAYS).days
    @items = model.site(site).lt(created: @threshold)
    @items
  end
end
