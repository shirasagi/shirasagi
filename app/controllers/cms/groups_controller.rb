# coding: utf-8
class Cms::GroupsController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  
  model SS::Group
  
  navi_view "cms/main/navi"
  menu_view "ss/crud/menu"
  
  private
    def set_crumbs
      @crumbs << [:"cms.group", action: :index]
    end
    
    def fix_params
      {}
    end
    
  public
    def index
      @items = @model.
        order_by(name: 1).
        page(params[:page]).per(50)
    end
end
