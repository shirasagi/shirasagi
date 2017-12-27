class Gws::Schedule::Todo::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::TodoFilter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('modules.addons.gws/schedule/todo'), gws_schedule_todo_main_path]
    @crumbs << [t('gws/schedule.tabs.trash'), action: :index]
  end

  def set_items
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      member(@cur_user).
      with_only_deleted.
      search(params[:s]).
      order_by(deleted: -1)
  end
end
