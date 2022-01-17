module Jmaxml::Addon::Trigger::Tsunami
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    cattr_accessor :control_title
    field :sub_types, type: SS::Extensions::Words
    embeds_ids :target_regions, class_name: "Jmaxml::TsunamiRegion"
    permit_params sub_types: [], target_region_ids: []
  end

  def verify(page, context, &block)
    control_title = REXML::XPath.first(context.xmldoc, '/Report/Control/Title/text()').to_s.strip
    return false unless control_title.start_with?(self.class.control_title)

    control_status = REXML::XPath.first(context.xmldoc, '/Report/Control/Status/text()').to_s.strip
    return false unless weather_xml_status_enabled?(control_status)

    return false unless fresh_xml?(page, context)

    area_codes = extract_tsunami_info(context.site, context.xmldoc)
    return false if area_codes.blank?

    context[:type] = Jmaxml::Type::TSUNAMI
    context[:area_codes] = area_codes

    return true unless block

    yield
  end

  private

  def extract_tsunami_info(site, xmldoc)
    area_codes = []
    REXML::XPath.match(xmldoc, '/Report/Body/Tsunami/Forecast/Item').each do |item|
      area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
      region = target_regions.site(site).where(code: area_code).first
      next if region.blank?

      # Category/Kind/Code の詳細については、
      # 気象庁防災情報XMLフォーマット 技術情報 (http://xml.kishou.go.jp/tec_material.html) の
      # 個別コード表 (http://xml.kishou.go.jp/jmaxml_20211224_Code.zip) に含まれる『地震火山関連コード表.xls』のシート "14" を参照
      kind_code = REXML::XPath.first(item, 'Category/Kind/Code/text()').to_s.strip
      case kind_code
      when '52', '53'
        kind_code = 'special_alert'
      when '51'
        kind_code = 'alert'
      when '62'
        kind_code = 'warning'
      when '71'
        kind_code = 'forecast'
      else
        # この else 節では以下のコードが想定されている。
        # 以下のコードは、解除もしくはダウングレードを示すコードなので無視する。
        #
        # 00: 津波なし（LastKind にだけ出現するようだ）
        # 50: 警報解除
        # 60: 津波注意報解除
        # 72: 津波注意報解除、津波予報（若干の海面変動）への切替
        # 73: 大津波警報または津波警報の解除、津波予報（若干の海面変動）への切替
        #
        kind_code = ''
      end
      next if kind_code.blank?
      next unless sub_types.include?(kind_code)

      area_codes << area_code
    end
    area_codes.sort
  end
end
