class Gws::Schedule::Todo::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::TodoFilter

  navi_view "gws/schedule/todo/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_todo_label || t('modules.addons.gws/schedule/todo'), gws_schedule_todo_main_path]
    @crumbs << [t('gws/schedule.tabs.trash'), action: :index]
  end

  def set_items
    @items = @model.site(@cur_site).
      allow(:trash, @cur_user, site: @cur_site).
      only_deleted.
      search(params[:s]).
      order_by(deleted: -1)
  end
end
