module Jmaxml::Helper::HeadHandler
  extend ActiveSupport::Concern

  def head_title
    REXML::XPath.first(xmldoc, '/Report/Head/Title/text()').to_s.strip
  end

  def head_headline_text
    REXML::XPath.first(xmldoc, '/Report/Head/Headline/Text/text()').to_s.strip
  end

  def head_target_datetime
    target_datetime = REXML::XPath.first(xmldoc, '/Report/Head/TargetDateTime/text()').to_s.strip
    if target_datetime.present?
      target_datetime = Time.zone.parse(target_datetime) rescue nil
    end
    target_datetime
  end

  def head_target_datetime_format(format = :long)
    time = head_target_datetime
    if time
      I18n.l(time, format: format)
    end
  end

  def head_info_type
    REXML::XPath.first(xmldoc, '/Report/Head/InfoType/text()').to_s.strip
  end
end
