# 土砂災害警戒情報
class Jmaxml::Trigger::LandslideInfo < Jmaxml::Trigger::Base
  embeds_ids :target_regions, class_name: "Jmaxml::ForecastRegion"
  permit_params target_region_ids: []

  def verify(page, context, &block)
    control_title = REXML::XPath.first(context.xmldoc, '/Report/Control/Title/text()').to_s.strip
    return false unless control_title.start_with?('土砂災害警戒情報')

    control_status = REXML::XPath.first(context.xmldoc, '/Report/Control/Status/text()').to_s.strip
    return false unless weather_xml_status_enabled?(control_status)

    return false unless fresh_xml?(page, context)

    area_codes = extract_weather_alert(context.site, context.xmldoc)
    return false if area_codes.blank?

    context[:type] = Jmaxml::Type::LAND_SLIDE
    context[:area_codes] = area_codes

    return true unless block_given?

    yield
  end

  private
    def extract_weather_alert(site, xmldoc)
      area_codes = []
      REXML::XPath.match(xmldoc, '/Report/Body/Warning[@type="土砂災害警戒情報"]/Item').each do |item|
        kind_code = REXML::XPath.first(item, 'Kind/Code/text()').to_s.strip
        next if kind_code.blank? || kind_code == '0'

        area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
        region = target_regions.site(site).where(code: area_code).first
        next if region.blank?

        area_codes << area_code
      end
      area_codes.sort
    end
end
