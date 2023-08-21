class Category::Node::ConfsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter
  include Category::IntegrationFilter

  model Category::Node::Base

  navi_view "cms/node/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_item
    @item = @cur_node
    @item.attributes = fix_params
  end

  def redirect_url
    node_conf_path
  end
end
