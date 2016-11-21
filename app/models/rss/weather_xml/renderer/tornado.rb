class Rss::WeatherXml::Renderer::Tornado < Rss::WeatherXml::Renderer::Base
  include Rss::WeatherXml::Renderer::ControlHandler
  include Rss::WeatherXml::Renderer::HeadHandler
  include Rss::WeatherXml::Renderer::EarthquakeHandler
  include Rss::WeatherXml::Renderer::CommentHandler

  template_variable_handler(:area_name, :template_variable_handler_area_name)

  private
    def title_template
      I18n.t('rss.templates.tornado.title')
    end

    def upper_html_template
      I18n.t('rss.templates.tornado.upper_html')
    end

    def loop_html_template
      I18n.t('rss.templates.tornado.loop_html')
    end

    def lower_html_template
      I18n.t('rss.templates.tornado.lower_html')
    end

    def render_loop_html(template)
      text = ''
      REXML::XPath.match(@context.xmldoc, '/Report/Body/Warning[@type="竜巻注意情報（市町村等）"]/Item').each do |item|
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
end
