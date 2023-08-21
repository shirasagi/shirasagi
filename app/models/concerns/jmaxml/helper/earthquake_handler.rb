module Jmaxml::Helper::EarthquakeHandler
  extend ActiveSupport::Concern

  def body_earthquake_origin_time
    time = REXML::XPath.first(xmldoc, '/Report/Body/Earthquake/OriginTime/text()').to_s.strip.presence
    if time.present?
      time = Time.zone.parse(time) rescue nil
    end
    time
  end

  def body_earthquake_origin_time_format(format = :long)
    time = body_earthquake_origin_time
    I18n.l(time, format: format) if time
  end

  def body_earthquake_magnitude
    magnitude = REXML::XPath.first(xmldoc, '/Report/Body/Earthquake/jmx_eb:Magnitude')
    ret = magnitude.text.to_s.strip.presence
    if ret == 'NaN'
      ret = magnitude.attributes['description'].to_s.strip.presence
    end
    ret
  end

  def body_earthquake_hypocenter_area_name
    REXML::XPath.first(xmldoc, '/Report/Body/Earthquake/Hypocenter/Area/Name/text()').to_s.strip.presence
  end

  def body_earthquake_hypocenter_area_coordinate
    coordinate = REXML::XPath.first(xmldoc, '/Report/Body/Earthquake/Hypocenter/Area/jmx_eb:Coordinate')
    return if coordinate.blank?

    coordinate.attributes['description'].to_s.strip.presence
  end

  def body_earthquake_hypocenter_area_namefrommark
    REXML::XPath.first(xmldoc, '/Report/Body/Earthquake/Hypocenter/Area/NameFromMark/text()').to_s.strip.presence
  end
end
