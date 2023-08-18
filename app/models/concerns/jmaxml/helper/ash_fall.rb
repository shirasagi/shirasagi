module Jmaxml::Helper::AshFall
  extend ActiveSupport::Concern
  include Jmaxml::Helper::Main

  def volcano_infos
    ret = REXML::XPath.match(@context.xmldoc, '/Report/Body/VolcanoInfo[@type="降灰予報（対象市町村等）"]/Item').map do |item|
      kind_name = REXML::XPath.first(item, 'Kind/Name/text()').to_s.strip
      area_names = REXML::XPath.match(item, 'Areas[@codeType="気象・地震・火山情報／市町村等"]/Area').map do |area|
        area_code = REXML::XPath.first(area, 'Code/text()').to_s.strip

        next nil unless @context.area_codes.include?(area_code)
        REXML::XPath.first(area, 'Name/text()').to_s.strip
      end

      area_names = area_names.compact.uniq
      next nil if area_names.blank?

      { kind_name: kind_name, area_names: area_names }
    end

    ret.compact
  end
end
