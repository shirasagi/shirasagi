module Map::FacilityHelper
  def render_marker_info(item, point = nil)
    categories = item.categories.order(depth: 1).to_a
    cate1 = categories.first
    cate2 = categories.last

    h = []
    h << %(<div class="marker-info" data-id="#{item.id}" data-cate-id="#{cate1.try(:id)}">)
    h << %(<p class="name">#{item.name}</p>)

    if point && point[:name].present?
      h << %(<p class="point-name">#{point[:name]}</p>)
    end

    h << %(<p class="form-name">#{cate2.name}</p>) if cate2

    if address = item.try(:address)
      h << %(<p class="address">#{address}</p>)
    end

    h << %(<p class="show"><a href="#{item.url}">#{I18n.t('ss.links.show')}</a></p>)
    h << %(</div>)

    h.join("\n")
  end

  def render_sidebar
    sidebar = []
    @items.map do |item|
      categories = item.categories.order(depth: 1).to_a
      cate1 = categories.first
      cate2 = categories.last

      h = []
      h << %(<div class="column" data-id="#{item.id}" data-cate-id="#{cate1.try(:id)}">)
      h << %(<p class="name"><a href="#{item.url}">#{item.name}</a></p>)
      h << %(<p class="form-name">#{cate2.name}</p>) if cate2

      if address = item.try(:address)
        h << %(<p class="address">#{address}</p>)
      end

      if item.map_points.present?
        h << %(<p><a href="#" class="click-marker">#{I18n.t("facility.sidebar.click_marker")}</a></p>)
      else
        h << %(<div class="no-marker">#{I18n.t("facility.sidebar.no_marker")}</div>)
      end
      h << %(</div>)
      sidebar << h.join("\n")
    end
    sidebar.join
  end
end
