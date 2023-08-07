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
    if SS::Lgwan.cms? && SS::Lgwan.map_layers.present? && !@generate_page
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
    map_options = opts[:map] || {}

    s = []
    case default_map_api(opts)
    when 'openlayers'
      include_openlayers_api
      layers = effective_layers(opts)

      map_options[:readonly] = true
      map_options[:markers] = markers if markers.present?
      map_options[:layers] = layers

      s << 'var opts = ' + map_options.to_json + ';'
      s << 'Openlayers_Facility_Search.render("' + selector + '", opts);'
    else
      include_googlemaps_api(opts)

      map_options[:markers] = markers if markers.present?
      map_options[:markerCluster] = true if opts[:markerCluster]

      s << 'var opts = ' + map_options.to_json + ';'
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

  ## render image picker

  def render_marker_picker(opts = {})
    h = []
    h << %w(<div class="images" style="display: none;">)
    map_marker_picker_images(opts).each do |url|
      h << "<div class=\"image\">#{image_tag(url)}</div>"
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
end
