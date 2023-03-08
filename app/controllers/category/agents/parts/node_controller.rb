class Category::Agents::Parts::NodeController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    @cur_node = @cur_part.parent

    path = @cur_main_path.sub(/\/[^\/]*$/, "")
    node = Category::Node::Base.site(@cur_site).filename(path).first || @cur_node

    if node && node.dirname
      cond = { filename: /^#{::Regexp.escape(node.dirname)}\//, depth: node.depth }
    elsif node
      cond = { filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1 }
    else
      cond = { depth: 1 }
    end

    @items = Category::Node::Base.site(@cur_site).and_public(@cur_date).
      where(cond).
      order_by(@cur_part.sort_hash).
      limit(@cur_part.limit)

    render
  end
end
