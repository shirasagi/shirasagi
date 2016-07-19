module Map::MapHelper
  def include_googlemaps_api(opts = {})
    map_setting = opts[:site].map_setting rescue {}

    key = opts[:api_key] || map_setting[:api_key] || SS.config.map.api_key

    params = {}
    params[:v] = 3
    params[:key] = key if key.present?
    controller.javascript "//maps.googleapis.com/maps/api/js?#{params.to_query}"
  end

  def include_openlayers_api
    controller.javascript "/assets/js/openlayers/ol.js"
    controller.stylesheet "/assets/js/openlayers/ol.css"
  end

  def render_map(selector, opts = {})
    map_setting = opts[:site].map_setting rescue {}

    api = opts[:api] || map_setting[:api] || SS.config.map.api
    #center = opts[:center]
    markers = opts[:markers]

    if api == "openlayers"
      include_openlayers_api

      s = []
      s << 'var canvas = $("' + selector + '")[0];'
      s << 'var opts = {'
      s << '  readonly: true,'
      s << '  markers: ' + markers.to_json + ',' if markers.present?
      s << '  layers: ' + SS.config.map.layers.to_json + ','
      s << '};'
      s << 'var map = new Openlayers_Map(canvas, opts);'
    else
      include_googlemaps_api(opts)

      s = []
      s << 'Map.load("' + selector + '");'
      s << 'Map.setMarkers(' + markers.to_json + ');' if markers.present?
    end

    jquery { s.join("\n").html_safe }
  end

  def render_map_form(selector, opts = {})
    map_setting = opts[:site].map_setting rescue {}

    api = opts[:api] || map_setting[:api] || SS.config.map.api
    center = opts[:center] || SS.config.map.map_center
    max_point_form = opts[:max_point_form] || SS.config.map.map_max_point_form
    #markers = opts[:markers]

    if api == "openlayers"
      include_openlayers_api

      s = []
      s << 'var canvas = $("' + selector + '")[0];'
      s << 'var opts = {'
      s << '  readonly: true,'
      s << '  center:' + center.reverse.to_json + ',' if center.present?
      s << '  layers: ' + SS.config.map.layers.to_json + ','
      s << '  max_point_form: ' + max_point_form.to_json + ',' if max_point_form.present?
      s << '};'
      s << 'var map = new Openlayers_Map_Form(canvas, opts);'
      s << 'SS_AddonTabs.hide(".mod-map");'
    else
      include_googlemaps_api(opts)

      s = []
      s << 'SS_AddonTabs.hide(".mod-map");'
      s << 'Map.center = ' + center.to_json + ';' if center.present?
      s << 'Map_Form.maxPointForm = ' + max_point_form.to_json + ';' if max_point_form.present?
      s << 'Map.setForm(Map_Form);'
      s << 'Map.load("' + selector + '");'
      s << 'Map.renderMarkers();'
      s << 'Map.renderEvents();'
      s << 'SS_AddonTabs.head(".mod-map").click(function() { Map.resize(); });'
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

      s << 'Map.center = ' + center.to_json + ';' if center.present?
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

    s = []
    if api == "openlayers"
      include_openlayers_api
      controller.javascript "/assets/js/exif-js.js"

      s = []
      s << 'var canvas = $("' + selector + '")[0];'
      s << 'var opts = {'
      s << '  readonly: true,'
      s << '  center:' + center.reverse.to_json + ',' if center.present?
      s << '  layers: ' + SS.config.map.layers.to_json + ','
      s << '};'
      s << 'var map = new Openlayers_Member_Photo_Form(canvas, opts);'
      s << 'map.setExifLatLng("#item_in_image");'
    else
      include_googlemaps_api(opts)
      controller.javascript "/assets/js/exif-js.js"

      s << 'Map.center = ' + center.to_json + ';' if center.present?
      s << 'Map.setForm(Member_Photo_Form);'
      s << 'Map.load("' + selector + '");'
      s << 'Map.renderMarkers();'
      s << 'Map.renderEvents();'
      s << 'Member_Photo_Form.setExifLatLng("#item_in_image");'
    end

    jquery { s.join("\n").html_safe }
  end

  def render_marker_info(item)
    h = []

    h << %(<div class="maker-info" data-id="#{item.id}">)
    h << %(<p class="name">#{item.name}</p>)
    h << %(<p class="address">#{item.address}</p>)
    h << %(<p class="show">#{link_to :show, item.url}</p>)
    h << %(</div>)

    h.join("\n")
  end
end
