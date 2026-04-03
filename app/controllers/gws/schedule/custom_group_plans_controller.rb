class Gws::Schedule::CustomGroupPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  before_action :set_group
  before_action :set_users, only: [:index, :print]

  navi_view "gws/schedule/main/navi"

  private

  def set_group
    @group ||= Gws::CustomGroup.site(@cur_site).find params[:group]
  end

  def set_crumbs
    set_group
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [@group.name, action: :index]
  end

  def set_users
    @users = @group.members.active.
      readable_users(@cur_user, site: @cur_site).
      order_by_title(@cur_site)
  end

  def set_items
    @items ||= Gws::Schedule::Plan.site(@cur_site).without_deleted
  end

  public

  def index
    # show custom groups
    @items = @items.search(params[:s])
  end
end
