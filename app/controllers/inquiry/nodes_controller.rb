class Inquiry::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Inquiry::Node::Form

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "inquiry/nodes/navi"

  before_action :redirect_with_route, only: :index

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "inquiry/form" }
    end

    def redirect_with_route
      if @cur_node.route == "inquiry/form"
        redirect_to inquiry_columns_path
      end
    end
end
