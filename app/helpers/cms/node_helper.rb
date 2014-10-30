module Cms::NodeHelper
  def contents_path(node)
    "/.#{node.site.host}/" + node.route.pluralize.sub("/", "#{node.id}/")
  rescue StandardError => e
    raise(e) unless Rails.env.production?
    node_nodes_path(cid: node)
  end

  def node_navi(opts = {}, &block)
    h  = []

    if block_given?
      h << capture(&block)
    end

    h << render(partial: "cms/node/main/node_navi")
    h << render(partial: "cms/node/main/modules")
    #h << render(partial: "cms/main/navi")
    h.join.html_safe
  end
end
