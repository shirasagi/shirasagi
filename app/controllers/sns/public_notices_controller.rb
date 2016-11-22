class Sns::PublicNoticesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Notice
  skip_action_callback :logged_in?, only: [:index, :show]

  layout "ss/login"
  navi_view nil

  private
    def set_crumbs
      @crumbs = []
    end

  public
    def index
      @items = @model.and_public.
        sys_admin_notice.
        search(params[:s]).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @item = @model.and_public.find(params[:id])
      render
    end
end
