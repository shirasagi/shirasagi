class Gws::PublicNoticesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  prepend_view_path "app/views/gws/notices"

  model Gws::Notice

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/notice", gws_public_notices_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      @items = @model.site(@cur_site).public.
        order_by(released: -1).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @item = @model.site(@cur_site).public.find(params[:id])
      raise "403" unless @item.public?
      render
    end
end
