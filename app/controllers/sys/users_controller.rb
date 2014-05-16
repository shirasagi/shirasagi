# coding: utf-8
class Sys::UsersController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  
  model SS::User
  
  private
    def set_crumbs
      @crumbs << [:"sys.user", sys_users_path]
    end
  
  public
    def index
      @items = @model.all.
        order_by(_id: -1)
    end
end
