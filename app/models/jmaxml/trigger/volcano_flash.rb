# 噴火速報
class Jmaxml::Trigger::VolcanoFlash < Jmaxml::Trigger::Base
  include Jmaxml::Addon::Trigger::VolcanoFlash

  def verify(page, context, &block)
    control_title = REXML::XPath.first(context.xmldoc, '/Report/Control/Title/text()').to_s.strip
    return false unless control_title.start_with?('噴火速報')

    control_status = REXML::XPath.first(context.xmldoc, '/Report/Control/Status/text()').to_s.strip
    return false unless weather_xml_status_enabled?(control_status)

    return false unless fresh_xml?(page, context)

    info_type = REXML::XPath.first(context.xmldoc, '/Report/Head/InfoType/text()').to_s.strip
    return verify_cancel(page, context, &block) if info_type == '取消'

    area_codes = extract_area_codes(context.site, context.xmldoc)
    return false if area_codes.blank?

    context[:type] = Jmaxml::Type::VOLCANO
    context[:area_codes] = area_codes

    return true unless block_given?

    yield
  end

  private

  def verify_cancel(page, context, &block)
    event_id = REXML::XPath.first(context.xmldoc, '/Report/Head/EventID/text()').to_s.strip
    return if event_id.blank?

    last_page_criteria = Rss::WeatherXmlPage.site(context.site).node(context.node)
    last_page_criteria = last_page_criteria.where(event_id: event_id).ne(id: page.id)
    last_page = last_page_criteria.order_by(id: -1).first
    return if last_page.blank?

    xmldoc = REXML::Document.new(last_page.weather_xml)
    area_codes = extract_area_codes(context.site, xmldoc)
    return false if area_codes.blank?

    context[:type] = Jmaxml::Type::VOLCANO
    context[:area_codes] = area_codes
    context[:last_page] = last_page
    context[:last_xmldoc] = xmldoc

    return true unless block_given?

    yield
  end

  def extract_area_codes(site, xmldoc)
    area_codes = []
    REXML::XPath.match(xmldoc, '/Report/Body/VolcanoInfo[@type="噴火速報（対象市町村等）"]/Item').each do |item|
      REXML::XPath.match(item, 'Areas[@codeType="気象・地震・火山情報／市町村等"]/Area/Code/text()').each do |area_code|
        area_code = area_code.to_s.strip
        region = target_regions.site(site).where(code: area_code).first
        next if region.blank?

        area_codes << area_code
      end
    end
    area_codes.sort
  end
end
