module Recommend
  class Initializer
    Cms::Part.plugin "recommend/history"
    Cms::Part.plugin "recommend/recommend"

    if SS.config.recommend.disable_recommendify.blank?
      # initialize_recommendify
      host = SS.config.recommend.redis["host"]
      port = SS.config.recommend.redis["port"]
      Recommendify.redis = Redis.new(host: host, port: port)
    end
  end
end
