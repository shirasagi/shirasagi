class Cms::Line::UpdateStatisticsJob < Cms::ApplicationJob
  queue_as :external

  def put_log(message)
    Rails.logger.info(message)
  end

  def perform
    now = Time.zone.today
    ids = Cms::Line::Statistic.site(site).pluck(:id)
    ids.each do |id|
      item = Cms::Line::Statistic.find(id) rescue nil
      next if item.nil?

      threshold = item.created.advance(days: 14).to_date
      if now <= threshold
        put_log("update #{item.id} #{item.name} (#{I18n.l(item.created)})")
        item.update_statistics
      end
    end
  end
end
