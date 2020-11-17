# 気象特別警報・警報・注意報
class Jmaxml::Trigger::WeatherAlert < Jmaxml::Trigger::Base
  include Jmaxml::Addon::Trigger::WeatherAlert

  def verify(page, context, &block)
    control_title = REXML::XPath.first(context.xmldoc, '/Report/Control/Title/text()').to_s.strip
    return false unless control_title.start_with?('気象特別警報・警報・注意報')

    control_status = REXML::XPath.first(context.xmldoc, '/Report/Control/Status/text()').to_s.strip
    return false unless weather_xml_status_enabled?(control_status)

    return false unless fresh_xml?(page, context)

    area_codes = extract_weather_alert(context.site, context.xmldoc)
    return false if area_codes.blank?

    context[:type] = Jmaxml::Type::FORECAST
    context[:area_codes] = area_codes

    return true unless block_given?

    yield
  end

  private

  def extract_weather_alert(site, xmldoc)
    area_codes = []
    REXML::XPath.match(xmldoc, '/Report/Body/Warning[@type="気象警報・注意報（市町村等）"]/Item').each do |item|
      kind_names = REXML::XPath.match(item, 'Kind/Name/text()').map { |n| n.to_s.strip }
      kind_names = kind_names.select do |kind_name|
        sub_type = sub_types.select(&:present?).select do |t|
          kind_name.include?(I18n.t("jmaxml.options.weather_alert_sub_type.#{t}"))
        end.first
        sub_type.present?
      end
      next if kind_names.blank?

      area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
      region = target_regions.site(site).where(code: area_code).first
      next if region.blank?

      area_codes << area_code
    end
    area_codes.sort
  end
end
