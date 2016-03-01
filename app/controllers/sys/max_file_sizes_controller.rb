class Sys::MaxFileSizesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model SS::MaxFileSize

  menu_view "sys/crud/menu"

  private
    def set_crumbs
      @crumbs << [:"sys.max_file_size", sys_max_file_sizes_path]
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user)
      @items = @model.allow(:edit, @cur_user).
        search(params[:s]).
        order_by(order: 1, name: 1, _id: -1).
        page(params[:page]).per(50)
    end
end
