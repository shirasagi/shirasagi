class Recommend::Agents::Parts::RecommendController < ApplicationController
  include Cms::PartFilter::View
  helper Recommend::ListHelper

  def index
    path = @cur_path
    path = path + "index.html" if @cur_path =~ /\/$/
    redis_key = Recommend::History::Log.redis_key(@cur_site, path)

    recommender = Recommend::History::Recommender.new
    neighbor_keys = recommender.for(redis_key).map(&:item_id)

    @limit = @cur_part.limit
    @items = Recommend::History::Log.from_redis_keys(@cur_site, neighbor_keys, @limit)
  end
end
