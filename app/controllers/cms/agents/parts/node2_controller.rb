class Cms::Agents::Parts::Node2Controller < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    case @cur_part.list_origin
    when "content"
      if @cur_page
        origin_content = @cur_page.parent
      elsif @cur_node
        origin_content = @cur_node.parent
      end
    else # "deployment"
      origin_content = @cur_part.parent
    end

    if origin_content
      @origin = origin_content
      cond = { filename: /^#{::Regexp.escape(origin_content.filename)}\//, depth: origin_content.depth + 1 }
    else
      cond = { depth: 1 }
    end

    node_routes = @cur_part.node_routes.select(&:present?)
    if node_routes.present?
      cond[:route] = { "$in" => node_routes }
    end

    @items = Cms::Node.site(@cur_site).and_public(@cur_date).
      where(cond).
      order_by(@cur_part.sort_hash).
      limit(@cur_part.limit)

    render
  end
end
