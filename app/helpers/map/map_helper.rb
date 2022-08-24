module Map::MapHelper
  DEFAULT_GOOGLEMAPS_API_END_POINT = "https://maps.googleapis.com/maps/api/js".freeze

  def map_enabled?(opts = {})
    return true unless opts[:site]
    return true if opts[:site].map_api_mypage == "active"
    (opts[:mypage] || opts[:preview]) ? false : true
  end

  def default_map_api(opts = {})
    map_setting = opts[:site].map_setting rescue {}
    opts[:api] || map_setting[:api] || SS.config.map.api
  end

  def effective_layers(opts = {})
    return unless opts[:site]
    if SS::Lgwan.enabled? && SS::Lgwan.map_layers.present? && !@generate_page
      SS::Lgwan.map_effective_layers(opts[:site])
    else
      opts[:site].map_effective_layers
    end
  end

  def show_google_maps_search(opts = {})
    return false unless opts[:site]
    opts[:site].show_google_maps_search_enabled?
  end

  def include_map_api(opts = {})
    return "" unless map_enabled?(opts)

    api = default_map_api(opts)
    if api == 'openlayers'
      include_openlayers_api
    else
      include_googlemaps_api(opts)
    end
  end

  def include_googlemaps_api(opts = {})
    map_setting = opts[:site].map_setting rescue {}

    key = opts[:api_key] || map_setting[:api_key] || SS.config.map.api_key
    language = opts[:language] || SS.config.map.language
    region = opts[:region] || SS.config.map.region
    params = {}
    params[:v] = 3
    params[:key] = key if key.present?
    params[:language] = language if language.present?
    params[:region] = region if region.present?
    controller.javascript "#{SS.config.map.googlemaps_api_end_point || DEFAULT_GOOGLEMAPS_API_END_POINT}?#{params.to_query}"
  end

  def include_openlayers_api
    controller.javascript "/assets/js/openlayers/ol.js"
    controller.stylesheet "/assets/js/openlayers/ol.css"
  end

  def render_map(selector, opts = {})
    return "" unless map_enabled?(opts)

    markers = opts[:markers]
    map_options = opts[:map] || {}
    center = opts[:center] || Map.center(opts[:site])
    s = []

    case default_map_api(opts)
    when 'openlayers'
      include_openlayers_api

      # set default values
      map_options[:readonly] = true
      map_options[:markers] = markers if markers.present?
      map_options[:layers] = effective_layers(opts)
      map_options[:showGoogleMapsSearch] = show_google_maps_search(opts)

      s << "Openlayers_Map.defaultCenter = [#{center.lat}, #{center.lng}];" if center
      s << "Openlayers_Map.defaultZoom = #{SS.config.map.openlayers_zoom_level};"
      s << 'var canvas = $("' + selector + '")[0];'
      s << "var opts = #{map_options.to_json};"
      s << 'var map = new Openlayers_Map(canvas, opts);'
    else
      include_googlemaps_api(opts)
      map_options[:showGoogleMapsSearch] = show_google_maps_search(opts)

      s << "Googlemaps_Map.defaultCenter = [#{center.lat}, #{center.lng}];" if center
      s << "Googlemaps_Map.defaultZoom = #{SS.config.map.googlemaps_zoom_level};"
      s << "Googlemaps_Map.load(\"" + selector + "\", #{map_options.to_json});"
      s << 'Googlemaps_Map.setMarkers(' + markers.to_json + ');' if markers.present?
    end

    jquery { s.join("\n").html_safe }
  end

  def render_map_form(selector, opts = {})
    return "" unless map_enabled?(opts)

    max_point_form = opts[:max_point_form] || Map.max_number_of_markers(opts[:site])
    map_options = opts[:map] || {}
    markers = opts[:markers]
    center = opts[:center] || Map.center(opts[:site])
    s = []
    s << 'SS_AddonTabs.findAddonView(".mod-map").one("ss:addonShown", function() {'

    case default_map_api(opts)
    when 'openlayers'
      include_openlayers_api

      # set default values
      map_options[:readonly] = true
      map_options[:markers] = markers if markers.present?
      map_options[:max_point_form] = max_point_form if max_point_form.present?
      map_options[:layers] = effective_layers(opts)
      map_options[:showGoogleMapsSearch] = show_google_maps_search(opts)

      # 初回アドオン表示後に地図を描画しないと、クリックした際にマーカーがずれてしまう
      s << "  Openlayers_Map.defaultCenter = [#{center.lat}, #{center.lng}];" if center
      s << "Openlayers_Map.defaultZoom = #{SS.config.map.openlayers_zoom_level};"
      s << '  var canvas = $("' + selector + '")[0];'
      s << "  var opts = #{map_options.to_json};"
      s << '  var map = new Openlayers_Map_Form(canvas, opts);'
    else
      include_googlemaps_api(opts)
      map_options[:showGoogleMapsSearch] = show_google_maps_search(opts)

      # 初回アドオン表示後に地図を描画しないと、ズームが 2 に初期設定されてしまう。
      s << "  Map_Form.maxPointForm = #{max_point_form.to_json};" if max_point_form.present?
      s << "  Googlemaps_Map.defaultCenter = [#{center.lat}, #{center.lng}];" if center
      s << "  Googlemaps_Map.defaultZoom = #{SS.config.map.googlemaps_zoom_level};"
      s << '  Googlemaps_Map.setForm(Map_Form);'
      s << "  Googlemaps_Map.load(#{selector.to_json}, #{map_options.to_json});"
      s << '  Googlemaps_Map.renderMarkers();'
      s << '  Googlemaps_Map.renderEvents();'
      s << '  SS_AddonTabs.findAddonView(".mod-map").on("ss:addonShown", function() {'
      s << '    Googlemaps_Map.resize();'
      s << '  });'
    end

    s << '});'
    jquery { s.join("\n").html_safe }
  end

  def render_facility_search_map(selector, opts = {})
    return "" unless map_enabled?(opts)

    markers = opts[:markers]

    s = []
    case default_map_api(opts)
    when 'openlayers'
      include_openlayers_api
      layers = effective_layers(opts)
      s << 'var opts = {'
      s << '  readonly: true,'
      s << '  markers: ' + markers.to_json + ',' if markers.present?
      s << '  layers: ' + layers.to_json + ','
      s << '};'
      s << 'Openlayers_Facility_Search.render("' + selector + '", opts);'
    else
      include_googlemaps_api(opts)

      s << 'var opts = {'
      s << '  markers: ' + (markers.try(:to_json) || '[]') + ','
      s << '  markerCluster: true,' if opts[:markerCluster]
      s << '};'
      s << 'Facility_Search.render("' + selector + '", opts);'
    end

    jquery { s.join("\n").html_safe }
  end

  def render_member_photo_form_map(selector, opts = {})
    return "" unless map_enabled?(opts)

    map_options = opts[:map] || {}
    markers = opts[:markers]
    center = opts[:center] || Map.center(opts[:site])

    s = []
    case default_map_api(opts)
    when 'openlayers'
      include_openlayers_api
      controller.javascript "/assets/js/exif-js.js"

      # set default values
      map_options[:readonly] = true
      map_options[:markers] = markers if markers.present?
      map_options[:layers] = effective_layers(opts)

      s << "Openlayers_Map.defaultCenter = [#{center.lat}, #{center.lng}];" if center
      s << "Openlayers_Map.defaultZoom = #{SS.config.map.openlayers_zoom_level};"
      s << 'var canvas = $("' + selector + '")[0];'
      s << "var opts = #{map_options.to_json};"
      s << 'var map = new Openlayers_Member_Photo_Form(canvas, opts);'
      s << 'map.setExifLatLng("#item_in_image");'
    else
      include_googlemaps_api(opts)
      controller.javascript "/assets/js/exif-js.js"

      s << "Googlemaps_Map.defaultCenter = [#{center.lat}, #{center.lng}];" if center
      s << "Googlemaps_Map.defaultZoom = #{SS.config.map.googlemaps_zoom_level};"
      s << 'Googlemaps_Map.setForm(Member_Photo_Form);'
      s << "Googlemaps_Map.load(\"" + selector + "\", #{map_options.to_json});"
      s << 'Googlemaps_Map.renderMarkers();'
      s << 'Googlemaps_Map.renderEvents();'
      s << 'Member_Photo_Form.setExifLatLng("#item_in_image");'
    end

    jquery { s.join("\n").html_safe }
  end

  def map_marker_address(item)
    if item.respond_to?(:column_values)
      item.column_values.each do |col|
        next unless col.name.start_with?('所在地', '住所')
        return col.value if col.value.present?
      end
    end
    return item.try(:address) ? item.address.presence : nil
  end

  def render_marker_info(item, point = nil)
    categories = item.categories.order(depth: 1).entries
    cate1 = categories.first
    cate2 = categories.last

    h = []
    h << %(<div class="marker-info" data-id="#{item.id}" data-cate-id="#{cate1.try(:id)}">)
    h << %(<p class="name">#{item.name}</p>)

    if point && point[:name].present?
      h << %(<p class="point-name">#{point[:name]}</p>)
    end

    h << %(<p class="form-name">#{cate2.name}</p>) if cate2

    if address = map_marker_address(item)
      h << %(<p class="address">#{address}</p>)
    end

    h << %(<p class="show"><a href="#{item.url}">#{I18n.t('ss.links.show')}</a></p>)
    h << %(</div>)

    h.join("\n")
  end

  def render_map_point_info(event, map_point)
    return if event_end_date(event).blank?
    return if event_end_date(event) <= Time.zone.today
    return if @items.present? && @items.where(id: event.id).blank?

    map_point_info(event, map_point)
  end

  def render_map_sidebar(item)
    categories = item.categories.order(depth: 1).entries
    cate1 = categories.first
    cate2 = categories.last

    h = []
    h << %(<div class="column" data-id="#{item.id}" data-cate-id="#{cate1.try(:id)}">)
    h << %(<p class="name"><a href="#{item.url}">#{item.name}</a></p>)
    h << %(<p class="form-name">#{cate2.name}</p>) if cate2

    if address = map_marker_address(item)
      h << %(<p class="address">#{address}</p>)
    end

    if item.map_points.present?
      h << %(<p><a href="#" class="click-marker">#{I18n.t("facility.sidebar.click_marker")}</a></p>)
    else
      h << %(<div class="no-marker">#{I18n.t("facility.sidebar.no_marker")}</div>)
    end
    h << %(</div>)

    h.join("\n")
  end

  def map_marker_picker_images(opts = {})
    api = default_map_api(opts)
    if %w(openlayers open_street_map).include?(api)
      SS.config.map.dig("map_marker_images", "openlayers", "picker")
    else
      SS.config.map.dig("map_marker_images", "googlemaps", "picker")
    end
  end

  def render_marker_picker(opts = {})
    h = []
    h << %w(<div class="images" style="display: none;">)
    map_marker_picker_images(opts).each do |url|
      h << "<div class=\"image\">#{image_tag(url)}</div>"
    end
    h << %(</div>)
    h.join("\n")
  end

  def render_facility_info(item)
    h = []
    h << render_marker_info(item)
    events = Event::Page.site(@cur_site).
      and_public.
      where(facility_ids: item.id).
      order(event_dates: "ASC").
      to_a
    events.select! do |event|
      next false if event_end_date(event).blank?
      next false if event_end_date(event) <= Time.zone.today
      next false if @items.present? && @items.where(id: event.id).blank?
      next false if event.map_points.blank?

      event.facility_ids.blank?
    end
    h << events_info(events)
    h.join("\n")
  end

  def monthly_map_point_info(event, map_point)
    map_point_info(event, map_point)
  end

  def monthly_facility_info(item, dates)
    h = []
    h << render_marker_info(item)
    events = Event::Page.site(@cur_site).and_public.where(facility_ids: item.id)
    events = events.in(event_dates: dates).
      entries.
      sort_by { |page| page.event_dates }
    events.select! do |event|
      next false if event.map_points.blank?

      event.facility_ids.blank?
    end
    h << events_info(events)
    h.join("\n")
  end

  def render_event_info(item, map_point)
    h = []
    if map_point[:name].present? || map_point[:text].present?
      h << %(<div class="maker-info">)
      h << %(<p class="name">#{map_point[:name]}</p>)
      h << %(<p class="text">#{map_point[:text]}</p>)
      h << %(</div>)
    end
    events = Event::Page.site(@cur_site).
      and_public.
      where(facility_ids: item.id).
      order(event_dates: "ASC").
      to_a
    events.select! do |event|
      next false if event_end_date(event).blank?
      next false if event_end_date(event) <= Time.zone.today
      next false if event.map_points.blank?

      event.facility_ids.blank?
    end
    h << events_info(events)
    h.join("\n")
  end

  private

  def map_point_info(event, map_point)
    h = []
    h << %(<div class="maker-info">)
    h << %(<p class="name">#{map_point[:name]}</p>)
    h << %(<p class="text">#{map_point[:text]}</p>)
    h << %(</div>)
    h << %(<div class="event-info">#{t("event.info")}(1#{t("event.count")}))
    h << %(<div class="event-list">)
    h << %(<div>)
    h << %(<p class="event-name">#{link_to event.name, event.url}</p>)
    h << %(<p class="event-dates">#{raw event.dates_to_html(:long)}</p>)
    h << %(</div>)
    h << %(</div>)
    h << %(</div>)
    h.join("\n")
  end

  def events_info(events)
    return '' if events.blank?

    h = []
    h << %(<div class="event-info">#{t("event.info")}(#{events.count}#{t("event.count")}))
    h << %(<div class="event-list">)
    events.each do |event|
      h << %(<div>)
      h << %(<p class="event-name">#{link_to event.name, event.url}</p>)
      h << %(<p class="event-dates">#{raw event.dates_to_html(:long)}</p>)
      h << %(</div>)
    end
    h << %(</div>)
    h << %(</div>)
    h.join("\n")
  end

  def event_end_date(event)
    event_dates = event.event_dates.clustered

    return if event_dates.blank?

    event_range = event_dates.first
    if event_dates.length > 1
      dates = event_dates.flatten.uniq.sort
      event_range = ::Icalendar::Values::Array.new(dates, ::Icalendar::Values::Date, {}, { delimiter: "," })
    end
    ::Icalendar::Values::Date.new(event_range.last.tomorrow.to_date)
  end
end
