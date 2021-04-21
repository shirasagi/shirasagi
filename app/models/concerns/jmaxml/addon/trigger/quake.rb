module Jmaxml::Addon::Trigger::Quake
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    cattr_accessor :control_title
    field :earthquake_intensity, type: String, default: '5+'
    embeds_ids :target_regions, class_name: "Jmaxml::QuakeRegion"
    permit_params :earthquake_intensity
    permit_params target_region_ids: []
    validates :earthquake_intensity, inclusion: { in: %w(0 1 2 3 4 5- 5+ 6- 6+ 7) }
  end

  def earthquake_intensity_options
    %w(4 5- 5+ 6- 6+ 7).map { |value| [I18n.t("rss.options.earthquake_intensity.#{value}"), value] }
  end

  def verify(page, context, &block)
    control_title = REXML::XPath.first(context.xmldoc, '/Report/Control/Title/text()').to_s.strip
    return false unless control_title.start_with?(self.class.control_title)

    control_status = REXML::XPath.first(context.xmldoc, '/Report/Control/Status/text()').to_s.strip
    return false unless weather_xml_status_enabled?(control_status)

    return false unless fresh_xml?(page, context)

    info_type = REXML::XPath.first(context.xmldoc, '/Report/Head/InfoType/text()').to_s.strip
    return verify_cancel(page, context, &block) if info_type == '取消'

    region_eq_infos = extract_earth_quake_info(context.site, context.xmldoc)
    return false if region_eq_infos.blank?

    max_int = region_eq_infos.max_by { |item| item[:area_max_int] }
    max_int = max_int[:area_max_int] if max_int.present?
    return false if compare_intensity(max_int, earthquake_intensity) < 0

    context[:type] = Jmaxml::Type::EARTH_QUAKE
    context[:region_eq_infos] = region_eq_infos
    context[:max_int] = max_int

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
    region_eq_infos = extract_earth_quake_info(context.site, xmldoc)
    return false if region_eq_infos.blank?

    max_int = region_eq_infos.max_by { |item| item[:area_max_int] }
    max_int = max_int[:area_max_int] if max_int.present?
    return false if compare_intensity(max_int, earthquake_intensity) < 0

    context[:type] = Jmaxml::Type::EARTH_QUAKE
    context[:region_eq_infos] = region_eq_infos
    context[:max_int] = max_int
    context[:last_page] = last_page
    context[:last_xmldoc] = xmldoc

    return true unless block_given?

    yield
  end

  def extract_earth_quake_info(site, xmldoc)
    region_eq_infos = []
    REXML::XPath.match(xmldoc, '/Report/Body/Intensity/Observation/Pref').each do |pref|
      pref_name = pref.elements['Name'].text
      pref_code = pref.elements['Code'].text
      REXML::XPath.match(pref, 'Area').each do |area|
        area_name = area.elements['Name'].text
        area_code = area.elements['Code'].text
        area_max_int = area.elements['MaxInt'].text

        region = target_regions.site(site).where(code: area_code).first
        next if region.blank?

        region_eq_infos << {
          pref_name: pref_name,
          pref_code: pref_code,
          area_name: area_name,
          area_code: area_code,
          area_max_int: area_max_int
        }
      end
    end
    region_eq_infos
  end

  def compare_intensity(lhs, rhs)
    normalize_intensity(lhs) <=> normalize_intensity(rhs)
  end

  def normalize_intensity(int)
    ret = int.to_s[0].to_i * 10
    ret += 1 if int[1] == '-'
    ret += 9 if int[1] == '+'
    ret
  end
end
