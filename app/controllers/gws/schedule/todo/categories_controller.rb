class Gws::Schedule::Todo::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/schedule/todo/main/navi"

  model Gws::Schedule::TodoCategory

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_todo_label || t('modules.addons.gws/schedule/todo'), gws_schedule_todo_main_path]
    @crumbs << [t('mongoid.models.gws/schedule/todo_category'), gws_schedule_todo_categories_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(order: 1).
      page(params[:page]).per(50)
  end
end
