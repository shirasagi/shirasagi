# coding: utf-8
class Map::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  model Map::Page

  append_view_path "app/views/cms/pages"
  navi_view "map/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { layout_id: @cur_node.layout_id }
    end

  public
    #Cms::PageFilter
end
