module Jmaxml::Helper::ControlHandler
  extend ActiveSupport::Concern

  def control_title
    REXML::XPath.first(xmldoc, '/Report/Control/Title/text()').to_s.strip.presence
  end

  def control_status
    REXML::XPath.first(xmldoc, '/Report/Control/Status/text()').to_s.strip.presence
  end

  def control_datetime
    datetime = REXML::XPath.first(xmldoc, '/Report/Control/DateTime/text()').to_s.strip.presence
    if datetime.present?
      datetime = Time.zone.parse(datetime) rescue nil
    end
    datetime
  end

  def control_datetime_format(format = :long)
    time = control_datetime
    if time
      I18n.l(time, format: format)
    end
  end

  def control_editorial_office
    REXML::XPath.first(xmldoc, '/Report/Control/EditorialOffice/text()').to_s.strip.presence
  end

  def control_publishing_office
    REXML::XPath.first(xmldoc, '/Report/Control/PublishingOffice/text()').to_s.strip.presence
  end
end
