class Recommend::Agents::Parts::HistoryController < ApplicationController
  include Cms::PartFilter::View
  helper Recommend::ListHelper

  def index
    token = cookies["_ss_recommend"] rescue nil
    @contents = Recommend::History::Log.site(@cur_site).
      where(token: token.to_s.presence).
      where(@cur_part.condition_hash).
      limit(100)
    @limit = @cur_part.limit
  end
end
