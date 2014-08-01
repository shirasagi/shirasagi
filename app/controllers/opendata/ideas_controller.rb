# coding: utf-8
class Opendata::IdeasController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  
  model Opendata::Idea
  
  navi_view "opendata/main/navi"
  
  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
    
  public
    def index
      @items = @model.site(@cur_site).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end
end
