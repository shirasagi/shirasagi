class Gws::Schedule::GroupPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  before_action :set_group
  before_action :set_users, only: [:index, :print]

  navi_view "gws/schedule/main/navi"

  private

  def set_group
    @group ||= Gws::Group.site(@cur_site).find params[:group]
    raise '404' unless @group.active?
  end

  def set_crumbs
    set_group
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [@group.trailing_name, action: :index]
  end

  def set_users
    @users = @group.users.active.
      readable(@cur_user, site: @cur_site, permission: false).
      order_by_title(@cur_site).compact
  end

  def set_items
    @items ||= begin
      Gws::Schedule::Plan.site(@cur_site).without_deleted.
        search(params[:s])
    end
  end

  public

  def index
    # show plans
  end
end
