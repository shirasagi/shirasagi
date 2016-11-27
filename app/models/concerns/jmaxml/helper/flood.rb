module Jmaxml::Helper::Flood
  extend ActiveSupport::Concern
  include Jmaxml::Helper::Main

  def main_sentences
    ret = []
    REXML::XPath.match(@context.xmldoc, '/Report/Body/Warning[@type="指定河川洪水予報"]/Item').each do |item|
      kind_property_type = REXML::XPath.first(item, 'Kind/Property/Type/text()').to_s.strip
      next if kind_property_type != '主文'

      area_code = REXML::XPath.match(item, 'Stations/Station/Code[@type="水位観測所"]/text()').first do |area_code|
        area_code = area_code.to_s.strip
        @context.area_codes.include?(area_code)
      end
      next if area_code.blank?

      kind_property_text = REXML::XPath.first(item, 'Kind/Property/Text/text()').to_s.strip

      ret << { body: kind_property_text }
    end
    ret
  end

  def flooding_areas
    ret = []
    REXML::XPath.match(@context.xmldoc, '/Report/Body/Warning[@type="指定河川洪水予報"]/Item').each do |item|
      kind_property_type = REXML::XPath.first(item, 'Kind/Property/Type/text()').to_s.strip
      next if kind_property_type != '浸水想定地区'

      REXML::XPath.match(item, 'Areas/Area[@codeType="水位観測所"]').each do |area|
        area_code = REXML::XPath.first(area, 'Code/text()').to_s.strip
        next unless @context.area_codes.include?(area_code)

        area_name = REXML::XPath.first(area, 'Name/text()').to_s.strip
        prefecture = REXML::XPath.first(area, 'Prefecture/text()').to_s.strip
        city = REXML::XPath.first(area, 'City/text()').to_s.strip
        sub_city_list = REXML::XPath.first(area, 'SubCityList/text()').to_s.strip

        ret << { area_name: area_name, prefecture: prefecture, city: city, sub_city_list: sub_city_list }
      end
    end
    ret
  end

  def rainfalls
    ret = []
    REXML::XPath.match(@context.xmldoc, '/Report/Body/MeteorologicalInfos[@type="雨量情報"]/MeteorologicalInfo/Item').each do |item|
      kind_property_type = REXML::XPath.first(item, 'Kind/Property/Type/text()').to_s.strip
      next if kind_property_type != '雨量'

      kind_property_text = REXML::XPath.first(item, 'Kind/Property/Text/text()').to_s.strip

      ret << { body: kind_property_text }
    end
    ret
  end
end
