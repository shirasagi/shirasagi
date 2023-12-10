class Gws::Schedule::Search::UsersController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  navi_view "gws/schedule/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/schedule.tabs.search'), gws_schedule_search_path]
    @crumbs << [t('gws/schedule.tabs.search/users'), gws_schedule_search_users_path]
  end

  public

  def index
    max = SS.config.gws.schedule['search_users']['max_users']

    @items = []
    return if params.dig(:s, :keyword).blank?

    count = Gws::User.site(@cur_site).active.
      readable_users(@cur_user, site: @cur_site).
      search(params[:s]).
      count

    @items = Gws::User.site(@cur_site).active.
      readable_users(@cur_user, site: @cur_site).
      search(params[:s]).
      order_by_title(@cur_site).
      limit(max)

    if count > max
      @item = Gws::Schedule::PlanSearch.new
      @item.errors.add :base, t('gws.errors.plan_search.max_users', count: max)
    end
  end
end
