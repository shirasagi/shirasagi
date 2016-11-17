module Rss::WeatherXml::Renderer::ControlHandler
  extend ActiveSupport::Concern

  included do
    template_variable_handler(:title, :template_variable_handler_title)
    template_variable_handler(:status, :template_variable_handler_status)
  end

  def control_title
    REXML::XPath.first(@context.xmldoc, '/Report/Control/Title/text()').to_s.strip.presence
  end

  def control_status
    REXML::XPath.first(@context.xmldoc, '/Report/Control/Status/text()').to_s.strip.presence
  end

  private
    def template_variable_handler_title(*_)
      control_title
    end

    def template_variable_handler_status(*_)
      control_status
    end
end
