class Cms::Agents::Parts::Node2Controller < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    node = @cur_node = @cur_part.parent
    if node
      filename = ::File.dirname(node.filename)
      cond = { filename: /^#{::Regexp.escape(filename)}\//, depth: node.depth }
    else
      cond = { depth: 1 }
    end

    node_routes = @cur_part.node_routes.select(&:present?)
    if node_routes.present?
      cond[:route] = { "$in" => node_routes }
    end

    @items = Cms::Node.site(@cur_site).and_public.
      where(cond).
      order_by(@cur_part.sort_hash).
      limit(@cur_part.limit)

    render
  end
end
