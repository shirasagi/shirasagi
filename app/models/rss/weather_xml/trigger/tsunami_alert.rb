class Rss::WeatherXml::Trigger::TsunamiAlert < Rss::WeatherXml::Trigger::Base
  embeds_ids :target_regions, class_name: "Rss::WeatherXml::TsunamiRegion"
  permit_params target_region_ids: []

  def verify(page, context, &block)
    control_title = REXML::XPath.first(context.xmldoc, '/Report/Control/Title/text()').to_s.strip
    return false unless %w(津波情報 津波警報・注意報・予報).include?(control_title)

    control_status = REXML::XPath.first(context.xmldoc, '/Report/Control/Status/text()').to_s.strip
    return false unless weather_xml_status_enabled?(control_status)

    return false unless fresh_xml?(page, context)

    area_codes = extract_tsunami_info(context.site, context.xmldoc)
    return false if area_codes.blank?

    context[:type] = Rss::WeatherXml::Type::TSUNAMI
    context[:area_codes] = area_codes

    return true unless block_given?

    yield
  end

  private
    def extract_tsunami_info(site, xmldoc)
      area_codes = []
      REXML::XPath.match(xmldoc, '/Report/Body/Tsunami/Forecast/Item').each do |item|
        area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
        region = target_regions.site(site).where(code: area_code).first
        next if region.blank?

        area_codes << area_code
      end
      area_codes
    end
end
