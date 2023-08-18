module Gws::TrashPurge::BaseJob
  extend ActiveSupport::Concern
  include SS::TrashPurge::BaseJob

  def perform(*_)
    count = @items.destroy_all
    Rails.logger.info "#{I18n.l(@threshold.to_date)}以前の#{model.model_name.human}を#{count}件削除しました。"
    puts_history(:info, "#{I18n.l(@threshold.to_date)}以前の#{model.model_name.human}を#{count}件削除しました。")
  end
end
