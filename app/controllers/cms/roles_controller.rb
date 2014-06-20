# coding: utf-8
class Cms::RolesController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  
  model Cms::Role
  
  navi_view "cms/main/navi"
  menu_view "ss/crud/menu"
  
  private
    def set_crumbs
      @crumbs << [:"cms.role", action: :index]
    end
    
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
    
  public
    def index
      @items = @model.
        order_by(name: 1).
        page(params[:page]).per(50)
    end
end
