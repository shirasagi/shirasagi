module Cms::NodeHelper
  def contents_path(node)
    route = node.view_route.present? ? node.view_route : node.route
     "/.s#{node.site.id}/" + route.pluralize.sub("/", "#{node.id}/")
  rescue StandardError => e
    raise(e) unless Rails.env.production?
    node_nodes_path(cid: node)
  end

  def node_navi(mod_name = nil, &block)
    h  = []

    if block_given?
      h << %(<nav class="mod-navi">).html_safe

      if mod_name
        mod_name = t("modules.#{mod_name}")
        h << mod_navi { %(<h2>#{mod_name}</h2>).html_safe }
      end

      h << capture(&block)
      h << %(</nav>).html_safe
    end

    h << render(partial: "cms/node/main/node_navi")
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
