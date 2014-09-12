# coding: utf-8
class Cms::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

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

      @items = @model.site(@cur_site)
        .allow(:read, @cur_user).
        where(depth: 1).
        where(route: "cms/page").
        search(params[:s]).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      raise "403" unless @item.allowed?(:release, @cur_user) if @item.state == "public"
      render_create @item.save
    end

    def update
      @item.attributes = get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      raise "403" unless @item.allowed?(:release, @cur_user) if @item.state == "public"
      render_update @item.update
    end
end
