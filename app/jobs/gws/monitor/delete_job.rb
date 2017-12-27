class Gws::Monitor::DeleteJob < Gws::ApplicationJob

  def perform(opts = {})
    threshold = parse_monitor_delete_threshold
    count = Gws::Monitor::Post.site(site).where(:deleted.lt => threshold).destroy_all

    Rails.logger.info "#{threshold}以前の照会・回答を#{count}件削除しました。"
    puts_history(:info, "#{threshold}以前の照会・回答を#{count}件削除しました。")
  end

  private

  def parse_monitor_delete_threshold
    return 24.months.ago if site.monitor_delete_threshold.blank?

    term, unit = site.monitor_delete_threshold.split('.')
    case unit.singularize
    when 'day'
      Integer(term).days.ago
    when 'month'
      Integer(term).months.ago
    when 'year'
      Integer(term).years.ago
    else
      24.months.ago
    end
  end
end

