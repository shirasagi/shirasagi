# coding: utf-8
class Cms::SitesController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  
  model SS::Site
  
  navi_view "cms/main/navi"
  menu_view "ss/crud/resource_menu"
  
  private
    def set_crumbs
      @crumbs << [:"cms.site", action: :show]
    end
    
    def fix_params
      {}
    end
    
    def set_item
      @item = @cur_site
      @item.attributes = fix_params
    end
    
  public
    def index
      @items = @model.
        order_by(name: 1).
        page(params[:page]).per(50)
    end
end
