module Jmaxml::Helper::Tornado
  extend ActiveSupport::Concern
  include Jmaxml::Helper::Main

  def area_names
    names = REXML::XPath.match(xmldoc, '/Report/Body/Warning[@type="竜巻注意情報（市町村等）"]/Item').map do |item|
      area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
      next unless @context.area_codes.include?(area_code)

      REXML::XPath.first(item, 'Area/Name/text()').to_s.strip
    end

    names.compact
  end
end
