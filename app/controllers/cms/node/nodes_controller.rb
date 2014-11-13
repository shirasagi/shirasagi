class Cms::Node::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Cms::Node

  navi_view "cms/node/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "cms/node" }
    end
end
