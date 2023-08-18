module Jmaxml::Helper::Tsunami
  extend ActiveSupport::Concern
  include Jmaxml::Helper::Main
 def info_group_by(target_sub_type)
    REXML::XPath.match(@context.xmldoc, '/Report/Body/Tsunami/Forecast/Item').map do |item|
      area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
      next nil unless @context.area_codes.include?(area_code)

      kind_code = REXML::XPath.first(item, 'Category/Kind/Code/text()').to_s.strip
      case kind_code
      when '52'
        kind_code = 'special_alert'
      when '51'
        kind_code = 'alert'
      when '62'
        kind_code = 'warning'
      when '71'
        kind_code = 'forecast'
      else
        kind_code = ''
      end
 next nil if kind_code != target_sub_type.to_s
      area_name = REXML::XPath.first(item, 'Area/Name/text()').to_s.strip
      first_wave = first_height_label(item)
      height = tsunami_height(item)

      { area_name: area_name, first_wave: first_wave, height: height }
    end.compact
                                                                                                                                                                                                        end

  def first_height_label(xml_node)
    first_height = xml_node.elements['FirstHeight']
    return if first_height.blank?

    condition = first_height.elements['Condition']
    if condition.present?
      return condition.text.to_s.strip
    end

    arrival_time = first_height.elements['ArrivalTime']
    if arrival_time.present?
      arrival_time = Time.zone.parse(arrival_time.text) rescue nil
      return I18n.l(arrival_time, format: :long) if arrival_time.present?
    end
  end

  def tsunami_height(xml_node)
    tsunami_height = REXML::XPath.first(xml_node, 'MaxHeight/jmx_eb:TsunamiHeight/text()').to_s.strip
    return if tsunami_height.blank?

    "#{tsunami_height}m"
  end
end
