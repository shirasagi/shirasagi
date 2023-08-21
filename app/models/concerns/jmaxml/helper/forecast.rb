module Jmaxml::Helper::Forecast
  extend ActiveSupport::Concern
  include Jmaxml::Helper::Main

  def each_areas(&block)
    REXML::XPath.match(@xmldoc, '/Report/Body/Warning[@type="気象警報・注意報（市町村等）"]/Item').each do |item|
      area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
      next unless @context.area_codes.include?(area_code)

      area_name = REXML::XPath.first(item, 'Area/Name/text()').to_s.strip

      kinds = REXML::XPath.match(item, 'Kind').map do |kind|
        kind_name = kind.elements['Name'].text.to_s.strip
        kind_code = kind.elements['Code'].text.to_s.strip
        kind_status = kind.elements['Status'].text.to_s.strip

        if kind_name =~ /特別警報/
          kind_type = 'special-alert'
        elsif kind_name =~ /警報/
          kind_type = 'alert'
        elsif kind_name =~ /注意報/
          kind_type = 'warning'
        end

        {
          kind_name: kind_status == '解除' ? "#{kind_name}#{kind_status}" : kind_name,
          kind_code: kind_code,
          kind_type: kind_type
        }
      end

      info = { area_code: area_code, area_name: area_name, kinds: kinds }

      yield info
    end
  end
end
