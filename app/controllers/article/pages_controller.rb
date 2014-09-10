# coding: utf-8
class Article::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::ApproveFilter

  model Article::Page

  append_view_path "app/views/cms/pages"
  navi_view "article/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { layout_id: @cur_node.layout_id }
    end

  public
    def index
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      @items = @model.site(@cur_site).node(@cur_node).allow(:read, @cur_user).
        search(params[:s]).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end
end
