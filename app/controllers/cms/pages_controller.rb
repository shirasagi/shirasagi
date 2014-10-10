class Cms::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model Cms::Page

  navi_view "cms/main/navi"
  menu_view "cms/main/node_menu"

  private
    def set_crumbs
      #@crumbs << [:"cms.page", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        where(route: "cms/page", depth: 1).
        allow(:read, @cur_user).
        search(params[:s]).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end
end
