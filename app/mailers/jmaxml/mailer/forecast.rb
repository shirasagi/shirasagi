class Jmaxml::Mailer::Forecast < Jmaxml::Mailer::Main
  def each_areas(&block)
    REXML::XPath.match(xmldoc, '/Report/Body/Warning[@type="気象警報・注意報（市町村等）"]/Item').each do |item|
      area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
      next unless @context.area_codes.include?(area_code)

      area_name = REXML::XPath.first(item, 'Area/Name/text()').to_s.strip

      kind_names = REXML::XPath.match(item, 'Kind').map do |kind|
        kind_name = kind.elements['Name'].text.to_s.strip
        kind_status = kind.elements['Status'].text.to_s.strip
        kind_status == '解除' ? "#{kind_name}#{kind_status}" : kind_name
      end

      info = { area_code: area_code, area_name: area_name, kind_names: kind_names }

      yield info
    end
  end
end
