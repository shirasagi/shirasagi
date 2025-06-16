class InquirySecond::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model InquirySecond::Node::Form

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "inquiry_second/nodes/navi"

  before_action :redirect_with_route, only: :index

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def pre_params
    { route: "inquiry_second/form" }
  end

  def redirect_with_route
    if @cur_node.route == "inquiry_second/form"
      redirect_to inquiry_second_columns_path
    end
  end
end
