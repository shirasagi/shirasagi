class Recommend::DestroyHistoryLogsJob < Cms::ApplicationJob
  def perform(opts = {})

    if site
      ids = Recommend::History::Log.site(site).pluck(:id)
    else
      ids = Recommend::History::Log.pluck(:id)
    end

    ids.each do |id|
      log = Recommend::History::Log.find(id) rescue nil
      next unless log

      Rails.logger.info("destroy: #{log.id} #{log.token} #{log.path}")
      log.destroy!
    end
  end
end
