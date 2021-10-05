module Cms::FormHelper
  def ancestral_layouts(node, cur_layout = nil)
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
    if cur_layout
      unless items.find { |_name, id| id == cur_layout.id }
        items.prepend([cur_layout.name, cur_layout.id])
      end
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

  def ancestral_loop_settings
    items = []
    Cms::LoopSetting.site(@cur_site).sort(order: 1, name: 1).each do |item|
      items << [item.name, item.id]
    end
    items
  end

  def ancestral_forms
    st_forms = @cur_node.becomes_with_route.st_forms rescue nil
    st_forms ||= Cms::Form.none
    st_forms = st_forms.and_public.allow(:read, @cur_user, site: @cur_site).order_by(update: 1)
    st_forms
  end
end
