# coding: utf-8
class Facility::FacilitiesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Facility::Node::Facility

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "facility/main/navi"

  private
    def set_item
      super
      raise "404" if @item.id == @cur_node.id
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "facility/facility" }
    end

  public
    def index
      @items = @model.site(@cur_site).node(@cur_node).
        allow(:read, @cur_user).
        order_by(filename: 1).
        page(params[:page]).per(50)
    end
end
