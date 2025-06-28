class Inquiry2::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Inquiry2::Node::Form

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "inquiry2/nodes/navi"

  before_action :redirect_with_route, only: :index

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def pre_params
    { route: "inquiry2/form" }
  end

  def redirect_with_route
    if @cur_node.route == "inquiry2/form"
      redirect_to inquiry2_columns_path
    end
  end
end
