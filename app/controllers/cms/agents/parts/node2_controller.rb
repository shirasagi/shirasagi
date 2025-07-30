class Cms::Agents::Parts::Node2Controller < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    origin_content = @cur_part.select_list_origin(@cur_page, @cur_node)

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
