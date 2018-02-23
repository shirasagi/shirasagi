class Gws::Schedule::CustomGroupPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  before_action :set_group

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

  def set_items
    @items = @group.sorted_members
  end

  public

  def index
  end
end
