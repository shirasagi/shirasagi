class Inquiry::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Inquiry::Node::Base

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "inquiry/nodes/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "inquiry/form" }
    end
end
