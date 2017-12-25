class Gws::Schedule::Todo::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  helper Gws::Schedule::PlanHelper
  model Gws::Schedule::Todo

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :recover, :active]
  before_action :set_selected_items, only: :active_all

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('modules.addons.gws/schedule/todo'), gws_schedule_todo_main_path]
    @crumbs << [t('gws/schedule.tabs.trash'), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).deleted.
      search(params[:s]).order_by(deleted: -1).page(params[:page]).per(50)
  end

  def recover
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def active
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.active, {notice: t('gws/schedule/todo_management.notice.active')}
  end

  def active_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        next if item.active
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end

    location = crud_redirect_url || { action: :index }
    notice = { notice: t('gws/schedule/todo_management.notice.active') }
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end
end
