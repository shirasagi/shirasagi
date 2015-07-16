module Cms::NodeHelper
  def contents_path(node)
    route = node.view_route.present? ? node.view_route : node.route
     "/.#{node.site.host}/" + route.pluralize.sub("/", "#{node.id}/")
  rescue StandardError => e
    raise(e) unless Rails.env.production?
    node_nodes_path(cid: node)
  end

  def node_navi(opts = {}, &block)
    h  = []
    h << render(partial: "cms/node/main/node_navi")

    h << %(<nav class="mod-navi">).html_safe
    h << capture(&block) if block_given?
    h << %(</nav>).html_safe

    #h << render(partial: "cms/main/navi")
    safe_join(h)
  end

  def mod_navi(&block)
    mods = Cms::Node.modules.map do |name, key|
      key = "node" if key == "cms" #TODO:
      %(<li>#{link_to name, send("#{key}_main_path")}</li>).html_safe
    end

    h  = []
    h << %(<div class="pulldown-menu">).html_safe
    h << capture(&block) if block_given?
    h << %(<ul>#{safe_join(mods)}</ul>).html_safe
    h << %(</div>).html_safe

    safe_join(h)
  end
end
