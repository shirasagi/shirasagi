class Recommend::Agents::Parts::HistoryController < ApplicationController
  include Cms::PartFilter::View
  helper Recommend::ListHelper

  def index
    token = cookies["_ss_recommend"] rescue nil
    @items = Recommend::History::Log.site(@cur_site).where(token: token).limit(100)
    @limit = @cur_part.limit
  end
end
