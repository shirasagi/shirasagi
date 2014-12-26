class Category::Agents::Parts::NodeController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  public
    def index
      @cur_node = @cur_part.parent

      path = @cur_path.sub(/\/[^\/]*$/, "")
      node = Category::Node::Base.site(@cur_site).filename(path).first || @cur_node

      if node && node.dirname
        cond = { filename: /^#{node.dirname}\//, depth: node.depth }
      elsif node
        cond = { filename: /^#{node.filename}\//, depth: node.depth + 1 }
      else
        cond = { depth: 1 }
      end

      @items = Category::Node::Base.site(@cur_site).public.
        where(cond).
        order_by(@cur_part.sort_hash).
        page(params[:page]).
        per(@cur_part.limit)

      render
    end
end
