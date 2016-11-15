module Rss::WeatherXml::Trigger::TsunamiBase
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    cattr_accessor :control_title
    embeds_ids :target_regions, class_name: "Rss::WeatherXml::TsunamiRegion"
    permit_params target_region_ids: []
  end

  def verify(page, context, &block)
    control_title = REXML::XPath.first(context.xmldoc, '/Report/Control/Title/text()').to_s.strip
    return false if control_title != self.class.control_title

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
      area_codes.sort
    end
end
