class Cms::LayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Layout

  navi_view "cms/main/navi"
  menu_view "cms/main/node_menu"

  private
    def set_crumbs
      #@crumbs << [:"cms.layout", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        allow(:read, @cur_user).
        where(depth: 1).
        search(params[:s]).
        order_by(filename: 1).
        page(params[:page]).per(50)
    end
end
