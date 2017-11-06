class Gws::Monitor::DeleteJob < Gws::ApplicationJob

  def perform(opts = {})
    case site.monitor_delete_threshold
    when 0 then
      threshold = 1.day.ago
    when 1 then
      threshold = 1.month.ago
    when 2..7 then
      threshold = (3 * (site.monitor_delete_threshold - 1)).month.ago
    when 8 then
      threshold = 24.months.ago
    end
    count = Gws::Monitor::Post.where(:deleted.lt => threshold).delete_all if threshold

    Rails.logger.info "#{threshold}以前の照会・回答を#{count}件削除しました。"
  end
end

