class Sys::PublicNoticesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Notice

  private
    def set_crumbs
      @crumbs << [:"cms.notice", action: :index]
    end

  public
    def index
      @items = @model.and_public.
        sys_admin_notice.
        search(params[:s]).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @model.and_public.find(@item.id)
      render
    end
end
