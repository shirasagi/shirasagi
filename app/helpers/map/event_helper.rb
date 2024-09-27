module Map::EventHelper
  def render_marker_info(item, point)
    h = []
    h << %(<div class="maker-info">)
    h << %(<p class="name">#{point[:name]}</p>)
    h << %(<div class="event-info">)
    h << %(<div class="event-list">)
    h << %(<p class="event-name"><a href="#{item.url}">#{item.name}</a></p>)
    h << %(<p class="event-dates">#{raw item.dates_to_html(:long)}</p>)
    h << %(<div>)
    h << %(</div>)

    h << %(</div>)
    h.join("\n")
  end
end
