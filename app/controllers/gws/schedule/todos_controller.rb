class Gws::Schedule::TodosController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  model Gws::Schedule::Todo
  helper Gws::Schedule::TodoHelper

  before_action :set_item, only: [ :show, :edit, :update, :delete, :destroy, :disable, :finish, :revert ]
  before_action :set_selected_items, only: [ :destroy_all, :disable_all, :finish_all, :revert_all ]

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('modules.addons.gws/schedule/todo'), gws_schedule_todos_path]
  end

  def pre_params
    super.keep_if { |key| %i[facility_ids].exclude?(key) }
  end

  def render_destroy_all(result)
    location = crud_redirect_url || { action: :index }
    notice = result ? { notice: t('gws/schedule/todo.notice.disable') } : {}
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).active.
      search(params[:s]).page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_create @item.save, location: redirection_url
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_update @item.update, location: redirection_url
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    @item.edit_range = params.dig(:item, :edit_range)
    @item.attributes["todo_action"] = params[:action]
    render_destroy @item.disable, {notice: t('gws/schedule/todo.notice.disable')}
  end

  def finish
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    return if request.get?
    @item.edit_range = params.dig(:item, :edit_range)
    @item.attributes["todo_action"] = params[:action]
    render_update @item.update(todo_state: 'finished')
  end

  def revert
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    return if request.get?
    @item.edit_range = params.dig(:item, :edit_range)
    @item.attributes["todo_action"] = params[:action]
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
