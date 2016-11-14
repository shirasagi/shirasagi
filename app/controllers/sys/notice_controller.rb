class Sys::NoticeController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Notice
  menu_view "sys/crud/menu"

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user)

    @items = @model.
      allow(:edit, @cur_user).
      search(params[:s]).
      order_by(released: -1).
      page(params[:page]).per(50)
  end

  def show

  end

  private
    def set_crumbs
      @crumbs << [:"sys.notice", action: :index]
    end

    def fix_params
      { cur_user: @cur_user }
    end
end
