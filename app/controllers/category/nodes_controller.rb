class Category::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter
  include Category::IntegrationFilter

  model Category::Node::Base

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "category/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def pre_params
    { route: "category/node" }
  end

  def redirect_url
    diff = @item.route !~ /^category\//
    diff ? node_node_path(cid: @cur_node, id: @item.id) : { action: :show, id: @item.id }
  end
end
