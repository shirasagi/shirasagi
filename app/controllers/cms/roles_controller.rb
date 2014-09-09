# coding: utf-8
class Cms::RolesController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter

  model Cms::Role

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"cms.role", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
      @items = @model.site(@cur_site).allow(:edit, @cur_user, site: @cur_site).
        order_by(name: 1).page(params[:page]).per(50)
    end

    def show
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render_create @item.save
    end

    def edit
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render
    end

    def update
      @item.attributes = get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render_update @item.update
    end

    def delete
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render
    end

    def destroy
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render_destroy @item.destroy
    end
end
