class Gws::Schedule::GroupPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  before_action :set_group
  before_action :set_users

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
    set_group
    @users = @group.users.active.order_by_title(@cur_site).compact
  end

  public

  def index
  end
end
