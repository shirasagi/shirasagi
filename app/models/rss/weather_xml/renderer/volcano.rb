class Rss::WeatherXml::Renderer::Volcano < Rss::WeatherXml::Renderer::Base
  include Rss::WeatherXml::Renderer::ControlHandler
  include Rss::WeatherXml::Renderer::HeadHandler
  include Rss::WeatherXml::Renderer::EarthquakeHandler
  include Rss::WeatherXml::Renderer::CommentHandler

  template_variable_handler(:area_name, :template_variable_handler_area_name)
  template_variable_handler(:volcano_headline, :template_variable_handler_volcano_headline)
  template_variable_handler(:volcano_activity, :template_variable_handler_volcano_activity)

  private
    def title_template
      I18n.t('rss.templates.volcano.title')
    end

    def upper_html_template
      I18n.t('rss.templates.volcano.upper_html')
    end

    def loop_html_template
      I18n.t('rss.templates.volcano.loop_html')
    end

    def lower_html_template
      I18n.t('rss.templates.volcano.lower_html')
    end

    def render_loop_html(template)
      text = ''
      REXML::XPath.match(@context.xmldoc, '/Report/Body/VolcanoInfo[@type="噴火速報（対象市町村等）"]/Item').each do |item|
        REXML::XPath.match(item, 'Areas[@codeType="気象・地震・火山情報／市町村等"]/Area').each do |area|
          next unless @context.area_codes.include?(area.elements['Code'].text.to_s.strip)

          text << render_template(template, area)
          text << "\n"
        end
      end
      text
    end

    def template_variable_handler_area_name(name, xml_node, *_)
      xml_node.elements['Name'].text.to_s.strip
    end

    def template_variable_handler_volcano_headline(*_)
      REXML::XPath.first(@context.xmldoc, '/Report/Body/VolcanoInfoContent/VolcanoHeadline/text()').to_s.strip
    end

    def template_variable_handler_volcano_activity(*_)
      REXML::XPath.first(@context.xmldoc, '/Report/Body/VolcanoInfoContent/VolcanoActivity/text()').to_s.strip
    end
end
