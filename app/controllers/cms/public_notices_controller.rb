class Cms::PublicNoticesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::SearchableCrudFilter

  model Cms::Notice

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"cms.notice", action: :index]
    end

  public
    def index
      @items = @model.site(@cur_site).and_public.target_to(@cur_user).
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
