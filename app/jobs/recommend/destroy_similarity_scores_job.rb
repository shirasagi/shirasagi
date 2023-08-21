class Recommend::DestroySimilarityScoresJob < Cms::ApplicationJob
  def perform(opts = {})

    if site
      ids = Recommend::SimilarityScore.site(site).pluck(:id)
    else
      ids = Recommend::SimilarityScore.pluck(:id)
    end

    ids.each do |id|
      log = Recommend::SimilarityScore.find(id) rescue nil
      next unless log

      Rails.logger.info("destroy: #{log.id} #{log.key} #{log.path}")
      log.destroy!
    end
  end
end
