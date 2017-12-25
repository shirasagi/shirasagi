class Gws::Schedule::Todo::ReadablesController < ApplicationController
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
    @crumbs << [t('modules.addons.gws/schedule/todo'), gws_schedule_todo_readables_path]
  end

  def pre_params
    super.keep_if { |key| %i[facility_ids].exclude?(key) }
  end

  def render_finish_all(result, opts = {})
    location = crud_redirect_url || { action: :index }
    notice = opts[:notice].presence || t("ss.notice.saved")
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { head json: errors }
      end
    end
  end

  public

  def index
    @items = @model.site(@cur_site).
      member_or_readable(@cur_user, site: @cur_site, include_role: true).
      without_deleted.
      search(params[:s]).
      custom_order(params.dig(:s, :sort) || 'updated_desc').
      page(params[:page]).per(50)
  end

  def show
    raise '403' if !@item.allowed?(:read, @cur_user, site: @cur_site) && !@item.member?(@cur_user) && !@item.readable(@cur_user)
    render
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    @item.edit_range = params.dig(:item, :edit_range)
    @item.todo_action = params[:action]
    render_destroy @item.disable, {notice: t('gws/schedule/todo.notice.disable')}
  end

  def finish
    raise '403' if !@item.allowed?(:edit, @cur_user, site: @cur_site) && !@item.member?(@cur_user)
    return if request.get?
    @item.edit_range = params.dig(:item, :edit_range)
    @item.todo_action = params[:action]
    render_update @item.update(todo_state: 'finished')
  end

  def revert
    raise '403' if !@item.allowed?(:edit, @cur_user, site: @cur_site) && !@item.member?(@cur_user)
    return if request.get?
    @item.edit_range = params.dig(:item, :edit_range)
    @item.todo_action = params[:action]
    render_update @item.update(todo_state: 'unfinished')
  end

  def finish_all
    error_items = []
    @items.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site) || item.member?(@cur_user)
        next if item.update(todo_state: 'finished')
      else
        item.errors.add :base, :auth_error
      end
      error_items << item
    end
    @items = error_items
    render_finish_all(@items.count == 0)
  end

  def revert_all
    error_items = []
    @items.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site) || item.member?(@cur_user)
        next if item.update(todo_state: 'unfinished')
      else
        item.errors.add :base, :auth_error
      end
      error_items << item
    end
    @items = error_items
    render_finish_all(@items.count == 0)
  end
end
