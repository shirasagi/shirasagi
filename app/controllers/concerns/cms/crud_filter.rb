# coding: utf-8
module Cms::CrudFilter
  extend ActiveSupport::Concern
  include SS::CrudFilter
  
  included do
    menu_view "cms/crud/menu"
  end
  
  public
    def index
      @items = @model.allow(read: @cur_user).order_by(_id: -1).page(params[:page]).per(100)
    end
    
    def show
      raise "403" unless @item.allowed?(read: @cur_user)
      render
    end
    
    def new
      @item = @model.new pre_params.merge(fix_params)
    end
    
    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(create: @cur_user)
      render_create @item.save
    end
    
    def edit
      raise "403" unless @item.allowed?(update: @cur_user)
      render
    end
    
    def update
      @item.attributes = get_params
      raise "403" unless @item.allowed?(update: @cur_user)
      render_update @item.update
    end
    
    def delete
      raise "403" unless @item.allowed?(delete: @cur_user)
      render
    end
    
    def destroy
      raise "403" unless @item.allowed?(delete: @cur_user)
      render_destroy @item.destroy
    end
end
