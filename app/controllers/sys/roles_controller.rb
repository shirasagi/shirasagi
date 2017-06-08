class Sys::RolesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Role

  prepend_view_path "app/views/ss/roles"
  menu_view "sys/crud/menu"

  private

  def set_crumbs
    @crumbs << [t("sys.role"), sys_roles_path]
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user)
    @items = @model.allow(:edit, @cur_user).
      order_by(name: 1).
      page(params[:page]).per(50)
  end
end
