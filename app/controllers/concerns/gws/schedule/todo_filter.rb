module Gws::Schedule::TodoFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path 'app/views/gws/schedule/todo/main'
    helper Gws::Schedule::TodoHelper
    model Gws::Schedule::Todo

    before_action :set_item, only: %i[show edit update delete destroy disable popup finish revert recover active]
    before_action :set_selected_items, only: [:destroy_all, :disable_all, :finish_all, :revert_all, :active_all]
  end

  private

  def pre_params
    super.keep_if { |key| %i[facility_ids].exclude?(key) }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
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
    set_items
    @items.page(params[:page]).per(50)
  end

  def show
    raise '403' if !@item.allowed?(:read, @cur_user, site: @cur_site) && !@item.member?(@cur_user) && !@item.readable?(@cur_user)
    render
  end

  def popup
    if @item.member?(@cur_user) || @item.readable?(@cur_user)
      render file: 'popup', layout: false
    else
      render file: 'popup_hidden', layout: false
    end
  end

  # 論理削除
  def disable
    @item.attributes = fix_params
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    return if request.get?
    @item.edit_range = params.dig(:item, :edit_range)
    @item.todo_action = params[:action]
    render_destroy @item.disable, {notice: t('gws/schedule/todo.notice.disable')}
  end

  # 完了にする
  def finish
    @item.attributes = fix_params
    raise '403' if !@item.allowed?(:edit, @cur_user, site: @cur_site) && !@item.member?(@cur_user)
    return if request.get?
    @item.edit_range = params.dig(:item, :edit_range)
    @item.todo_action = params[:action]
    render_update @item.update(todo_state: 'finished')
  end

  # 未完了にする
  def revert
    @item.attributes = fix_params
    raise '403' if !@item.allowed?(:edit, @cur_user, site: @cur_site) && !@item.member?(@cur_user)
    return if request.get?
    @item.edit_range = params.dig(:item, :edit_range)
    @item.todo_action = params[:action]
    render_update @item.update(todo_state: 'unfinished')
  end

  # 削除を取り消す
  def active
    @item.attributes = fix_params
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    return if request.get?
    render_destroy @item.active, {notice: t('gws/schedule/todo.notice.active')}
  end

  # すべて完了にする
  def finish_all
    error_items = []
    @items.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site) || item.member?(@cur_user)
        item.attributes = fix_params
        next if item.update(todo_state: 'finished')
      else
        item.errors.add :base, :auth_error
      end
      error_items << item
    end
    @items = error_items
    render_finish_all(@items.count == 0)
  end

  # すべて未完了にする
  def revert_all
    error_items = []
    @items.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site) || item.member?(@cur_user)
        item.attributes = fix_params
        next if item.update(todo_state: 'unfinished')
      else
        item.errors.add :base, :auth_error
      end
      error_items << item
    end
    @items = error_items
    render_finish_all(@items.count == 0)
  end

  # すべての削除を取り消す
  def active_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        item.attributes = fix_params
        next if item.active
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end

    location = crud_redirect_url || { action: :index }
    notice = { notice: t('gws/schedule/todo.notice.active') }
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end
end
