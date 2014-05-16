# coding: utf-8
class Sys::GroupsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  
  model SS::Group
  
  private
    def set_crumbs
      @crumbs << [:"sys.group", sys_groups_path]
    end
  
  public
    def index
      @items = @model.all.
        order_by(name: 1)
    end
end
