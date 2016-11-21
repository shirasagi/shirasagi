class Rss::WeatherXml::Renderer::Tsunami < Rss::WeatherXml::Renderer::Base
  include Rss::WeatherXml::Renderer::ControlHandler
  include Rss::WeatherXml::Renderer::HeadHandler
  include Rss::WeatherXml::Renderer::EarthquakeHandler
  include Rss::WeatherXml::Renderer::CommentHandler

  template_variable_handler(:area_name, :template_variable_handler_area_name)
  template_variable_handler(:category_name, :template_variable_handler_category_name)
  template_variable_handler(:first_height_label, :template_variable_handler_first_height_label)
  template_variable_handler(:tsunami_height, :template_variable_handler_tsunami_height)

  def title_template
    I18n.t('rss.templates.tsunami.title')
  end

  def upper_html_template
    I18n.t('rss.templates.tsunami.upper_html')
  end

  def loop_html_template
    I18n.t('rss.templates.tsunami.loop_html')
  end

  def lower_html_template
    I18n.t('rss.templates.tsunami.lower_html')
  end

  private
    def render_loop_html(template)
      text = ''
      REXML::XPath.match(@context.xmldoc, '/Report/Body/Tsunami/Forecast/Item').each do |item|
        area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
        next unless @context.area_codes.include?(area_code)

        text << render_template(template, item)
        text << "\n"
      end
      text
    end

    def template_variable_handler_area_name(name, xml_node, *_)
      REXML::XPath.first(xml_node, 'Area/Name/text()').to_s.strip
    end

    def template_variable_handler_category_name(name, xml_node, *_)
      REXML::XPath.first(xml_node, 'Category/Kind/Name/text()').to_s.strip
    end

    def template_variable_handler_first_height_label(name, xml_node, *_)
      first_height = xml_node.elements['FirstHeight']
      return if first_height.blank?

      arrival_time = first_height.elements['ArrivalTime']
      if arrival_time.present?
        arrival_time = Time.zone.parse(arrival_time.text) rescue nil
        return I18n.l(arrival_time, format: :long) if arrival_time.present?
      end

      condition = first_height.elements['Condition']
      if condition.present?
        return condition.text.to_s.strip
      end
    end

    def template_variable_handler_tsunami_height(name, xml_node, *_)
      tsunami_height = REXML::XPath.first(xml_node, 'MaxHeight/jmx_eb:TsunamiHeight/text()').to_s.strip
      return if tsunami_height.blank?

      "#{tsunami_height}m"
    end
end
