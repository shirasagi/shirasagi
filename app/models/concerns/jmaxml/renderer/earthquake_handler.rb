module Jmaxml::Renderer::EarthquakeHandler
  extend ActiveSupport::Concern

  included do
    template_variable_handler(:earthquake_origin_time, :template_variable_handler_earthquake_origin_time)
    template_variable_handler(:earthquake_magnitude, :template_variable_handler_earthquake_magnitude)
    template_variable_handler(:hypocenter_area_name, :template_variable_handler_hypocenter_area_name)
    template_variable_handler(:hypocenter_coordinate, :template_variable_handler_hypocenter_coordinate)
    template_variable_handler(:hypocenter_name_from_mark, :template_variable_handler_hypocenter_namefrommark)
  end

  def body_earthquake_origin_time
    time = REXML::XPath.first(@context.xmldoc, '/Report/Body/Earthquake/OriginTime/text()').to_s.strip.presence
    if time.present?
      time = Time.zone.parse(time) rescue nil
    end
    time
  end

  def body_earthquake_magnitude
    magnitude = REXML::XPath.first(@context.xmldoc, '/Report/Body/Earthquake/jmx_eb:Magnitude')
    ret = magnitude.text.to_s.strip.presence
    if ret == 'NaN'
      ret = magnitude.attributes['description'].to_s.strip.presence
    end
    ret
  end

  def body_earthquake_hypocenter_area_name
    REXML::XPath.first(@context.xmldoc, '/Report/Body/Earthquake/Hypocenter/Area/Name/text()').to_s.strip.presence
  end

  def body_earthquake_hypocenter_area_coordinate
    coordinate = REXML::XPath.first(@context.xmldoc, '/Report/Body/Earthquake/Hypocenter/Area/jmx_eb:Coordinate')
    return if coordinate.blank?

    coordinate.attributes['description'].to_s.strip.presence
  end

  def body_earthquake_hypocenter_area_namefrommark
    REXML::XPath.first(@context.xmldoc, '/Report/Body/Earthquake/Hypocenter/Area/NameFromMark/text()').to_s.strip.presence
  end

  private
    def template_variable_handler_earthquake_origin_time(*_)
      I18n.l(body_earthquake_origin_time, format: :long)
    end

  def template_variable_handler_earthquake_magnitude(*_)
    body_earthquake_magnitude
  end

  def template_variable_handler_hypocenter_area_name(*_)
    body_earthquake_hypocenter_area_name
  end

  def template_variable_handler_hypocenter_coordinate(*_)
    body_earthquake_hypocenter_area_coordinate
  end

  def template_variable_handler_hypocenter_namefrommark(*_)
    body_earthquake_hypocenter_area_namefrommark
  end
end
