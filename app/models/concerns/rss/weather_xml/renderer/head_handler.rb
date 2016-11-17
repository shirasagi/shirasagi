module Rss::WeatherXml::Renderer::HeadHandler
  extend ActiveSupport::Concern

  included do
    template_variable_handler(:headline_text, :template_variable_handler_headline_text)
    template_variable_handler(:target_time, :template_variable_handler_target_time)
    template_variable_handler(:info_type, :template_variable_handler_info_type)
  end

  def head_headline_text
    REXML::XPath.first(@context.xmldoc, '/Report/Head/Headline/Text/text()').to_s.strip
  end

  def head_target_datetime
    target_datetime = REXML::XPath.first(@context.xmldoc, '/Report/Head/TargetDateTime/text()').to_s.strip
    if target_datetime.present?
      target_datetime = Time.zone.parse(target_datetime) rescue nil
    end
    target_datetime
  end

  def head_info_type
    REXML::XPath.first(@context.xmldoc, '/Report/Head/InfoType/text()').to_s.strip
  end

  private
    def template_variable_handler_headline_text(*_)
      head_headline_text
    end

    def template_variable_handler_target_time(*_)
      I18n.l(head_target_datetime, format: :long)
    end

    def template_variable_handler_info_type(*_)
      head_info_type
    end
end
