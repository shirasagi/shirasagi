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
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(released: -1).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @item = @model.site(@cur_site).and_public.find(params[:id])
      raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
      render
    end
end
