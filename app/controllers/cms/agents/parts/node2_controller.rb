class Cms::Agents::Parts::Node2Controller < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    case @cur_part.list_origin
    when "content"
      if @cur_page
        origin_content = @cur_page
      else
        origin_content = @cur_node
      end
    else # "deployment"
      origin_content = @cur_node = @cur_part.parent
    end

    origin_parent = origin_content.parent if origin_content
    if origin_parent
      cond = { filename: /^#{::Regexp.escape(origin_parent.filename)}\//, depth: origin_content.depth }
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
