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
