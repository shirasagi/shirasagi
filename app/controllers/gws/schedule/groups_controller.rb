class Gws::Schedule::GroupsController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/schedule.tabs.group'), action: :index]
  end

  public

  def index
    @items = @cur_site.descendants.active.tree_sort(root_name: @cur_site.name)
  end
end
