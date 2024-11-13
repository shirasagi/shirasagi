class Cms::Apis::ContentQuotaNaviController < ApplicationController
  include Cms::ApiFilter

  model Cms::Node

  def index
    @routes = SS.config.content_quota.dig("navi", "routes")
    @items = Cms::Node.site(@cur_site).
      in(route: @routes).
      in(group_ids: @cur_user.group_ids).
      where(shortcut: 'show').
      page(params[:page]).
      per(10)
  end
end
