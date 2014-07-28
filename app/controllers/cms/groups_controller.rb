# coding: utf-8
class Cms::GroupsController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  
  model Cms::Group
  
  navi_view "cms/main/navi"
  
  private
    def set_crumbs
      @crumbs << [:"cms.group", action: :index]
    end
    
    def fix_params
      {}
    end
    
    def set_item
      super
      raise "403" unless Cms::Group.site(@cur_site).include?(@item)
    end
    
  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
      @items = @model.allow(:edit, @cur_user, site: @cur_site).site(@cur_site).
        order_by(name: 1).
        page(params[:page]).per(50)
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
