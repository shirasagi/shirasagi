module Map
  module_function

  SYSTEM_LIMIT_NUMBER_OF_MARKERS = 100
  DEFAULT_MAX_NUMBER_OF_MARKERS = 10

  def system_limit_number_of_markers
    SS.config.map.map_system_limit_number_of_markers || SYSTEM_LIMIT_NUMBER_OF_MARKERS
  end

  def default_max_number_of_markers
    SS.config.map.map_max_point_form || DEFAULT_MAX_NUMBER_OF_MARKERS
  end

  def max_number_of_markers(site)
    site.try(:map_max_number_of_markers) || Map.default_max_number_of_markers
  end

  def center(site)
    map_center = site.try(:map_center)
    if map_center
      lng = site.map_center.try(:lng)
      lat = site.map_center.try(:lat)
    end
    if !lng || !lat
      lng = SS.config.map.map_center[1]
      lat = SS.config.map.map_center[0]
    end

    OpenStruct.new(lng: lng, lat: lat)
  end

  # API KEY などが漏洩しないようにホワイトリスト方式でエクスポートする（webpack.config.js の MAP_CONFIG_EXPORTS と同じ項目）
  def to_config
    {
      map: {
        map_center: SS.config.map.map_center,
        map_marker_images: SS.config.map.map_marker_images,
        googlemaps_zoom_level: SS.config.map.googlemaps_zoom_level,
        googlemaps_search_end_point: SS.config.map.googlemaps_search_end_point,
        openlayers_zoom_level: SS.config.map.openlayers_zoom_level
      }
    }
  end
end
