# coding: utf-8
class Facility::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model Facility::Page

  append_view_path "app/views/cms/pages"
  navi_view "facility/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { layout_id: @cur_node.layout_id }
    end

  #public
    #Cms::PageFilter
end
