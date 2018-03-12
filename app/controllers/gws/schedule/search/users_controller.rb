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
    @items = []
    return if params.dig(:s, :keyword).blank?

    @items = Gws::User.site(@cur_site).active.
      readable(@cur_user, site: @cur_site, permission: false).
      search(params[:s]).
      order_by_title(@cur_site)
  end
end
