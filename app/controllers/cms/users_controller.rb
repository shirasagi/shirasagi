# coding: utf-8
class Cms::UsersController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  
  model Cms::User
  
  navi_view "cms/main/navi"
  menu_view "ss/crud/menu"
  
  private
    def set_crumbs
      @crumbs << [:"cms.user", action: :index]
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
