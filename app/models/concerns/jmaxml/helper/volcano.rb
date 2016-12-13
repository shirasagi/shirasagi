module Jmaxml::Helper::Volcano
  extend ActiveSupport::Concern
  include Jmaxml::Helper::Main

  def area_names
    names = REXML::XPath.match(@context.xmldoc, '/Report/Body/VolcanoInfo[@type="噴火速報（対象市町村等）"]/Item').map do |item|
      REXML::XPath.match(item, 'Areas[@codeType="気象・地震・火山情報／市町村等"]/Area').map do |area|
        next unless @context.area_codes.include?(area.elements['Code'].text.to_s.strip)
        area.elements['Name'].text.to_s.strip
      end
    end

    names.flatten.compact.uniq
  end
end
