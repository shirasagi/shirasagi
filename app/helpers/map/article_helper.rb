module Map::ArticleHelper
  def render_marker_info(item, point = nil)
    source = @cur_node.map_marker_liquid.presence || @cur_node.default_map_marker_liquid
    assigns = { "page" => item, "node" => @cur_node, "point" => point.to_h }
    template = ::Cms.parse_liquid(source, liquid_registers)
    template.render(assigns).html_safe
  end

  def render_sidebar
    source = @cur_node.sidebar_loop_liquid.presence || @cur_node.default_sidebar_loop_liquid
    assigns = { "pages" => @items, "node" => @cur_node }
    template = ::Cms.parse_liquid(source, liquid_registers)
    template.render(assigns).html_safe
  end
end
