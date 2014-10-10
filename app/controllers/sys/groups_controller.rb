class Sys::GroupsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Group

  menu_view "sys/crud/menu"

  private
    def set_crumbs
      @crumbs << [:"sys.group", sys_groups_path]
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user)
      @items = @model.allow(:edit, @cur_user).
        order_by(name: 1)
    end
end
