module Rss::WeatherXml::Renderer::ControlHandler
  extend ActiveSupport::Concern

  included do
    template_variable_handler(:title, :template_variable_handler_title)
    template_variable_handler(:status, :template_variable_handler_status)
    template_variable_handler(:editorial_office, :template_variable_handler_editorial_office)
    template_variable_handler(:publishing_office, :template_variable_handler_publishing_office)
  end

  def control_title
    REXML::XPath.first(@context.xmldoc, '/Report/Control/Title/text()').to_s.strip.presence
  end

  def control_status
    REXML::XPath.first(@context.xmldoc, '/Report/Control/Status/text()').to_s.strip.presence
  end

  def control_editorial_office
    REXML::XPath.first(@context.xmldoc, '/Report/Control/EditorialOffice/text()').to_s.strip.presence
  end

  def control_publishing_office
    REXML::XPath.first(@context.xmldoc, '/Report/Control/PublishingOffice/text()').to_s.strip.presence
  end

  private
    def template_variable_handler_title(*_)
      control_title
    end

    def template_variable_handler_status(*_)
      control_status
    end

    def template_variable_handler_editorial_office(*_)
      control_editorial_office
    end

    def template_variable_handler_publishing_office(*_)
      control_publishing_office
    end
end
