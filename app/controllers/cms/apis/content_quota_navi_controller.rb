class Cms::Apis::ContentQuotaNaviController < ApplicationController
  include Cms::ApiFilter

  model Cms::Node

  private

  def routes
    @routes ||= SS.config.content_quota.dig("navi", "routes")
  end

  def set_items
    @items ||= Cms::Node.all
                        .site(@cur_site)
                        .in(route: routes)
                        .in(group_ids: @cur_user.group_ids)
                        .where(shortcuts: Cms::Node::SHORTCUT_QUOTA)
  end

  public

  def index
    set_items
    @items = @items.page(params[:page]).per(10)
  end
end
