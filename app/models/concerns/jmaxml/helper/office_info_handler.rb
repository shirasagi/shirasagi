module Jmaxml::Helper::OfficeInfoHandler
  extend ActiveSupport::Concern

  def office_info_names
    REXML::XPath.match(xmldoc, '/Report/Body/OfficeInfo/Office/Name/text()').map(&:to_s).map(&:strip)
  end
end
