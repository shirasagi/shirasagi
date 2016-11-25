class Jmaxml::Mailer::Landslide < Jmaxml::Mailer::Main
  def landslide_infos
    REXML::XPath.match(@context.xmldoc, '/Report/Body/Warning[@type="土砂災害警戒情報"]/Item').map do |item|
      area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
      next nil unless @context.area_codes.include?(area_code)

      area_name = REXML::XPath.first(item, 'Area/Name/text()').to_s.strip
      kind_name = REXML::XPath.first(item, 'Kind/Name/text()').to_s.strip
      kind_code = REXML::XPath.first(item, 'Kind/Code/text()').to_s.strip
      kind_status = REXML::XPath.first(item, 'Kind/Status/text()').to_s.strip

      { area_code: area_code, area_name: area_name, kind_name: kind_name, kind_code: kind_code, kind_status: kind_status }
    end.compact
  end
end
