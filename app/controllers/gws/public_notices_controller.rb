class Gws::PublicNoticesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Notice

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/notice", action: :index]
    end

  public
    def index
      @items = @model.site(@cur_site).and_public.
        readable(@cur_user, @cur_site, exclude_role: true).
        search(params[:s]).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @model.site(@cur_site).and_public.readable(@cur_user, @cur_site).find(@item.id)
      render
    end
end
