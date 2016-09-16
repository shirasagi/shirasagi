class Recommend::CreateMatrixJob < Cms::ApplicationJob
  def perform(days = nil)
    delete_matrix

    term = {}
    term = { :created.gte => Time.zone.now.advance(days: days.to_i * -1 ) } if days.present?
    recommender = Recommend::History::Recommender.new
    tokens = Recommend::History::Log.where(term).pluck(:token).uniq
    tokens.each do |token|
      logs = Recommend::History::Log.where(term).where(token: token)
      items = logs.map(&:redis_key).uniq
      Rails.logger.info("#{token} [#{items.join(", ")}]")
      recommender.order_items.add_set(token, items)
    end
    recommender.process!
  end

  def delete_matrix
    Recommendify.redis.del "recommendify:order_items:ccmatrix"
    Recommendify.redis.del "recommendify:similarities"
    Recommendify.redis.del "recommendify:order_items:items"
  end
end
