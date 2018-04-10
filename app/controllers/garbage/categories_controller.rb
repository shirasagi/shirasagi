class Garbage::CategoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Garbage::Node::Base

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def index
    redirect_to node_nodes_path
    return
  end
end
