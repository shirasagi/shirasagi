module Jmaxml::Helper::VolcanoHandler
  extend ActiveSupport::Concern

  def volcano_info_content_volcano_headline
    REXML::XPath.first(xmldoc, '/Report/Body/VolcanoInfoContent/VolcanoHeadline/text()').to_s.strip
  end

  def volcano_info_content_volcano_activity
    REXML::XPath.first(xmldoc, '/Report/Body/VolcanoInfoContent/VolcanoActivity/text()').to_s.strip
  end

  def volcano_info_content_volcano_prevention
    REXML::XPath.first(xmldoc, '/Report/Body/VolcanoInfoContent/VolcanoPrevention/text()').to_s.strip
  end

  def volcano_info_content_appendix
    REXML::XPath.first(xmldoc, '/Report/Body/VolcanoInfoContent/Appendix/text()').to_s.strip
  end
end
