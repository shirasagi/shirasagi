class Sys::GroupsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Group

  menu_view "sys/crud/menu"

  private

  def set_crumbs
    @crumbs << [t("sys.group"), sys_groups_path]
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user)

    @items = @model.allow(:edit, @cur_user).
      state(params.dig(:s, :state)).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user)
    render_destroy @item.disable
  end

  def destroy_all
    disable_all
  end

  def role_edit
    set_item
    return "404" if @item.users.blank?
    render :role_edit
  end

  def role_update
    set_item
    role_ids = params[:item][:sys_role_ids].select(&:present?).map(&:to_i)

    @item.users.each do |user|
      user.set(sys_role_ids: role_ids)
    end
    render_update true
  end
end
