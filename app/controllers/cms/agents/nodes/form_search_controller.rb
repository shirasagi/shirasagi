class Cms::Agents::Nodes::FormSearchController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  model Cms::Node::FormSearch

  private

  def set_search_params
    @s ||= Cms::FormSearchParam.new(
      cur_site: @cur_site, cur_user: @cur_user, cur_node: @cur_node, s: params[:s].try(:to_unsafe_h)
    )
  end

  def pages
    if @cur_node.conditions.present?
      condition_hash = @cur_node.condition_hash
    else
      condition_hash = @cur_node.parent.try(:condition_hash)
      condition_hash ||= @cur_node.condition_hash
    end

    Cms::Page.site(@cur_site).and_public(@cur_date).where(condition_hash)
  end

  def set_items
    @items = pages.where(@s.condition_hash).
      order_by(@s.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)
  end

  public

  def index
    set_search_params
    set_items
    render_with_pagination @items
  end
end
