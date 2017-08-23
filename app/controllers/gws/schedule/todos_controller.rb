class Gws::Schedule::TodosController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  model Gws::Schedule::Todo
  helper Gws::Schedule::TodoHelper

  before_action :set_item, only: [
      :show, :edit, :update, :delete, :destroy,
      :disable, :finish, :revert
  ]

  before_action :set_selected_items, only: [
      :destroy_all, :disable_all,
      :finish_all, :revert_all
  ]

  private

  def set_crumbs
    @crumbs << [t('modules.gws/schedule'), gws_schedule_plans_path]
    @crumbs << [t('modules.addons.gws/schedule/todo'), gws_schedule_todos_path]
  end

  def pre_params
    super.keep_if {|key| %i(facility_ids).exclude?(key)}
  end

  public

  def index
    @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        active().
        search(params[:s]).
        page(params[:page]).per(50)
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable
  end

  def finish
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(todo_state: 'finished')
  end

  def revert
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(todo_state: 'unfinished')
  end

  def finish_all
    raise '403' unless @items.allowed?(:edit, @cur_user, site: @cur_site)
    @items.update_all(todo_state: 'finished')
    render_destroy_all(false)
  end

  def revert_all
    raise '403' unless @items.allowed?(:edit, @cur_user, site: @cur_site)
    @items.update_all(todo_state: 'unfinished')
    render_destroy_all(false)
  end
end
