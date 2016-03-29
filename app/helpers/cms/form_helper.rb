module Cms::FormHelper
  def ancestral_layouts(node)
    node  = @cur_node if !node || node.new_record?
    items = []
    if node
      Cms::Layout.site(@cur_site).node(node).sort(name: 1).each do |item|
        items << ["#{node.name}/#{item.name}", item.id]
      end
      node.parents.sort(depth: -1).each do |parent|
        Cms::Layout.site(@cur_site).node(parent).sort(name: 1).each do |item|
          items << ["#{parent.name}/#{item.name}", item.id]
        end
      end
    end
    Cms::Layout.site(@cur_site).where(depth: 1).sort(name: 1).each do |item|
      items << [item.name, item.id]
    end
    items
  end

  def ancestral_body_layouts
    items = []
    Cms::BodyLayout.site(@cur_site).sort(name: 1).each do |item|
      items << [item.name, item.id] if item.parts.present?
    end
    items
  end

  def show_path_with_route(item)
    model = item.class.name.underscore.sub(/^.+?\//, "").sub(/\/.+$/, "")

    path = "cms_#{model}_path".to_sym
    return send(path, id: item.id) if item.parent.blank?

    if item.respond_to?(:route) && model == "page"
      route = item.route =~ /cms\// ? "node_page" : item.route.tr("/", "_")
      path  = "#{route}_path".to_sym
      return send(path, cid: item.parent.id, id: item.id) if respond_to?(path)
    end

    path = "node_#{model}_path".to_sym
    return send(path, cid: item.parent.id, id: item.id)
  rescue
    nil
  end

  def show_image_info(file)
    return nil unless file

    image = file.thumb || file
    link  = %(<a href="#{file.url}" target="_blank">).html_safe

    h = []
    h << %(<div>#{link}#{image_tag(image.url, alt: "")}</a></div>).html_safe
    h << %(<div>#{link}#{file.filename}</a> \(#{number_to_human_size(file.size)}\)</div>).html_safe

    safe_join(h)
  end
end
