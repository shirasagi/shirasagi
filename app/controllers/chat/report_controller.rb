class Chat::ReportController < ApplicationController
  include Cms::BaseFilter
  include History::LogFilter::View

  model Chat::History

  navi_view "cms/node/main/navi"

  private

  def set_crumbs
    @crumbs << [I18n.t('chat.report'), action: :index]
  end

  def cond
    { site_id: @cur_site.id }
  end
end
