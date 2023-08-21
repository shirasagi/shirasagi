class Sys::UsersController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model SS::User

  menu_view "sys/crud/menu"

  before_action :set_selected_items, only: [:destroy_all, :lock_all, :unlock_all]

  private

  def set_crumbs
    @crumbs << [t("sys.user"), sys_users_path]
  end

  def fix_params
    { cur_user: @cur_user }
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user)
    @items = @model.allow(:edit, @cur_user).
      state(params.dig(:s, :state)).
      search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user)
    render_destroy @item.disabled? ? @item.destroy : @item.disable
  end

  def destroy_all
    disable_all
  end

  def lock_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site)
        item.attributes = fix_params
        next if item.lock
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size, notice: t('ss.notice.lock_user_all'))
  end

  def unlock_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site)
        item.attributes = fix_params
        next if item.unlock
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size, notice: t('ss.notice.unlock_user_all'))
  end
end
