class Recommend::CreateSimilarityScoresJob < Cms::ApplicationJob
  def perform(days = nil)
    Rails.logger.info("destroy old similarity scores")
    destroy_similarity_scores

    days = days.to_i
    days = 7 if days <= 0
    term = { "$gte" => Time.zone.now.advance(days: days * -1 ) }
    Rails.logger.info("aggregation history logs(#{days}days)")

    match = {
      "$and" => [
        { :site_id => site.id },
        { :created => term }
      ]
    }
    prefs = Recommend::History::Log.to_path_axis_aggregation(match)

    Rails.logger.info("create similarity scores and save in db")
    max_neighbors = SS.config.recommend.max_neighbors
    count = prefs.count
    prefs.keys.each_with_index do |key, idx|
      Rails.logger.info("#{idx + 1}/#{count} #{key}")

      saved_scores = 0
      scores = matches(prefs, key)
      scores.each do |value, score|
        break if saved_scores >= max_neighbors

        if score > 0.0
          Recommend::SimilarityScore.new(site: site, key: key, path: value, score: score).save!
          saved_scores += 1
        end
      end
    end
  end

  def matches(prefs, target)
    scores = []
    prefs.each do |key, value|
      next if key == target
      scores << [ key, sim_jaccard(prefs, target, key) ]
    end
    scores.sort_by { |score| score[1] }.reverse
  end

  def sim_jaccard(prefs, item1, item2)
    item_and = (prefs[item1].keys & prefs[item2].keys)
    item_or = (prefs[item1].keys | prefs[item2].keys)

    if item_or.empty? || item_and.empty?
      return 0.0
    else
      return (item_and.size.to_f / item_or.size.to_f)
    end
  end

  def destroy_similarity_scores
    Recommend::SimilarityScore.site(site).destroy_all
  end
end
