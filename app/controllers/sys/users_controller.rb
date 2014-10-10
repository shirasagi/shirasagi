class Sys::UsersController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::User

  menu_view "sys/crud/menu"

  private
    def set_crumbs
      @crumbs << [:"sys.user", sys_users_path]
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user)
      @items = @model.allow(:edit, @cur_user).
        order_by(_id: -1)
    end
end
