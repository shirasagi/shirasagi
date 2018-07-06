module Map::MapHelper
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
    controller.javascript "//maps.googleapis.com/maps/api/js?#{params.to_query}"
  end

  def include_openlayers_api
    controller.javascript "/assets/js/openlayers/ol.js"
    controller.stylesheet "/assets/js/openlayers/ol.css"
  end

  def render_map(selector, opts = {})
    map_setting = opts[:site].map_setting rescue {}

    api = opts[:api] || map_setting[:api] || SS.config.map.api
    markers = opts[:markers]
    map_options = opts[:map] || {}

    if api == "openlayers"
      include_openlayers_api

      # set default values
      map_options[:readonly] = true
      map_options[:markers] = markers if markers.present?
      map_options[:layers] = SS.config.map.layers

      s = []
      s << 'var canvas = $("' + selector + '")[0];'
      s << "var opts = #{map_options.to_json};"
      s << 'var map = new Openlayers_Map(canvas, opts);'
    else
      include_googlemaps_api(opts)

      s = []
      s << "Googlemaps_Map.load(\"" + selector + "\", #{map_options.to_json});"
      s << 'Googlemaps_Map.setMarkers(' + markers.to_json + ');' if markers.present?
    end

    jquery { s.join("\n").html_safe }
  end

  def render_map_form(selector, opts = {})
    map_setting = opts[:site].map_setting rescue {}

    api = opts[:api] || map_setting[:api] || SS.config.map.api
    center = opts[:center] || SS.config.map.map_center
    max_point_form = opts[:max_point_form] || SS.config.map.map_max_point_form
    map_options = opts[:map] || {}

    if api == "openlayers"
      include_openlayers_api

      # set default values
      map_options[:readonly] = true
      map_options[:center] = center.reverse if center.present?
      map_options[:layers] = SS.config.map.layers
      map_options[:max_point_form] = max_point_form if max_point_form.present?

      s = []
      s << 'var canvas = $("' + selector + '")[0];'
      s << "var opts = #{map_options.to_json};"
      s << 'var map = new Openlayers_Map_Form(canvas, opts);'
      s << 'SS_AddonTabs.hide(".mod-map");'
    else
      include_googlemaps_api(opts)

      s = []
      s << 'SS_AddonTabs.hide(".mod-map");'
      s << 'Googlemaps_Map.center = ' + center.to_json + ';' if center.present?
      s << 'Map_Form.maxPointForm = ' + max_point_form.to_json + ';' if max_point_form.present?
      s << 'Googlemaps_Map.setForm(Map_Form);'
      s << "Googlemaps_Map.load(\"" + selector + "\", #{map_options.to_json});"
      s << 'Googlemaps_Map.renderMarkers();'
      s << 'Googlemaps_Map.renderEvents();'
      s << 'SS_AddonTabs.head(".mod-map").click(function() { Googlemaps_Map.resize(); });'
    end

    jquery { s.join("\n").html_safe }
  end

  def render_facility_search_map(selector, opts = {})
    map_setting = opts[:site].map_setting rescue {}

    api = opts[:api] || map_setting[:api] || SS.config.map.api
    center = opts[:center] || SS.config.map.map_center
    markers = opts[:markers]

    s = []
    if api == "openlayers"
      include_openlayers_api

      s << 'var opts = {'
      s << '  readonly: true,'
      s << '  center:' + center.reverse.to_json + ',' if center.present?
      s << '  markers: ' + markers.to_json + ',' if markers.present?
      s << '  layers: ' + SS.config.map.layers.to_json + ','
      s << '};'
      s << 'Openlayers_Facility_Search.render("' + selector + '", opts);'
    else
      include_googlemaps_api(opts)

      s << 'Googlemaps_Map.center = ' + center.to_json + ';' if center.present?
      s << 'var opts = {'
      s << '  markers: ' + markers.to_json + ',' if markers.present?
      s << '};'
      s << 'Facility_Search.render("' + selector + '", opts);'
    end

    jquery { s.join("\n").html_safe }
  end

  def render_member_photo_form_map(selector, opts = {})
    map_setting = opts[:site].map_setting rescue {}

    api = opts[:api] || map_setting[:api] || SS.config.map.api
    center = opts[:center] || SS.config.map.map_center
    map_options = opts[:map] || {}

    s = []
    if api == "openlayers"
      include_openlayers_api
      controller.javascript "/assets/js/exif-js.js"

      # set default values
      map_options[:readonly] = true
      map_options[:center] = center.reverse if center.present?
      map_options[:layers] = SS.config.map.layers

      s = []
      s << 'var canvas = $("' + selector + '")[0];'
      s << "var opts = #{map_options.to_json};"
      s << 'var map = new Openlayers_Member_Photo_Form(canvas, opts);'
      s << 'map.setExifLatLng("#item_in_image");'
    else
      include_googlemaps_api(opts)
      controller.javascript "/assets/js/exif-js.js"

      s << 'Googlemaps_Map.center = ' + center.to_json + ';' if center.present?
      s << 'Googlemaps_Map.setForm(Member_Photo_Form);'
      s << "Googlemaps_Map.load(\"" + selector + "\", #{map_options.to_json});"
      s << 'Googlemaps_Map.renderMarkers();'
      s << 'Googlemaps_Map.renderEvents();'
      s << 'Member_Photo_Form.setExifLatLng("#item_in_image");'
    end

    jquery { s.join("\n").html_safe }
  end

  def render_marker_info(item)
    h = []
    h << %(<div class="maker-info" data-id="#{item.id}">)
    h << %(<p class="name">#{item.name}</p>)
    h << %(<p class="address">#{item.address}</p>)
    h << %(<p class="show">#{link_to t('ss.links.show'), item.url}</p>)
    h << %(</div>)

    h.join("\n")
  end
end
