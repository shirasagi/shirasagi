class Chat::HistoryController < ApplicationController
  include Cms::BaseFilter
  include History::LogFilter::View

  model Chat::History

  navi_view "cms/node/main/navi"

  private

  def set_crumbs
    @crumbs << [@model.model_name.human, action: :index]
  end

  def cond
    { site_id: @cur_site.id }
  end
end
