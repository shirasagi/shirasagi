module Map::MapHelper
  def render_marker_info(item)
    html = []

    html << %(<div class="maker-info" data-id="#{item.id}">)
    html << %(<p class="name">#{item.name}</p>)
    html << %(<p class="address">#{item.address}</p>)
    html << %(<p class="show">#{link_to :show, item.url}</p>)
    html << %(</div>)

    html.join("\n")
  end
end
