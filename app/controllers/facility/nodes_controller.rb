class Facility::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Facility::Node::Node

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "facility/main/navi"
  menu_view "facility/page/menu"

  private
    def set_item
      super
      raise "404" if @item.id == @cur_node.id
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "facility/node" }
    end

  public
    def index
      redirect_to facility_pages_path
      return
    end
end
