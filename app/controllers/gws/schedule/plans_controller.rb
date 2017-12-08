class Gws::Schedule::PlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/schedule.tabs.personal'), gws_schedule_plans_path]
  end

  public

  def index
    return render if params[:format] != 'json'

    @items = Gws::Schedule::Plan.site(@cur_site).
      member(@cur_user).
      #allow(:read, @cur_user, site: @cur_site).
      search(params[:s])
  end

  def events
    @items = Gws::Schedule::Plan.site(@cur_site).
      member(@cur_user).
      search(params[:s])

    @todos = Gws::Schedule::Todo.site(@cur_site).active.
      member(@cur_user).
      search(params[:s])
  end
end
