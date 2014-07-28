# coding: utf-8
class Event::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Event::Page

  append_view_path "app/views/cms/pages"
  navi_view "event/main/navi"
  menu_view false

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def index
      render inline: "", layout: true
      
      #@items = @model.site(@cur_site).node(@cur_node).allow(:read, @cur_user).
      #  order_by(updated: -1).
      #  page(params[:page]).per(50)
    end
end
