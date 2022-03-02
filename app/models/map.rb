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
end
