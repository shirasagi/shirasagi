# 降灰予報
class Jmaxml::Trigger::AshFallForecast < Jmaxml::Trigger::Base
  field :sub_types, type: SS::Extensions::Words
  embeds_ids :target_regions, class_name: "Jmaxml::ForecastRegion"
  permit_params sub_types: [], target_region_ids: []

  def verify(page, context, &block)
    control_title = REXML::XPath.first(context.xmldoc, '/Report/Control/Title/text()').to_s.strip
    return false unless control_title.start_with?('降灰予報')

    sub_type = sub_types.first { |t| control_title.include?(I18n.t("rss.options.ash_fall_sub_type.#{t}")) }
    return false if sub_type.blank?

    control_status = REXML::XPath.first(context.xmldoc, '/Report/Control/Status/text()').to_s.strip
    return false unless weather_xml_status_enabled?(control_status)

    return false unless fresh_xml?(page, context)

    area_codes = extract_area_codes(context.site, context.xmldoc)
    return false if area_codes.blank?

    context[:type] = Jmaxml::Type::ASH_FALL
    context[:area_codes] = area_codes

    return true unless block_given?

    yield
  end

  private
    def extract_area_codes(site, xmldoc)
      area_codes = []
      REXML::XPath.match(xmldoc, '/Report/Body/VolcanoInfo[@type="降灰予報（対象市町村等）"]/Item').each do |item|
        REXML::XPath.match(item, 'Areas[@codeType="気象・地震・火山情報／市町村等"]/Area/Code/text()').each do |area_code|
          area_code = area_code.to_s.strip
          region = target_regions.site(site).where(code: area_code).first
          next if region.blank?

          area_codes << area_code
        end
      end
      area_codes.sort.uniq
    end
end
