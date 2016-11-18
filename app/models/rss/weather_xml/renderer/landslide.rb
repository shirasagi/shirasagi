class Rss::WeatherXml::Renderer::Landslide < Rss::WeatherXml::Renderer::Base
  include Rss::WeatherXml::Renderer::ControlHandler
  include Rss::WeatherXml::Renderer::HeadHandler
  include Rss::WeatherXml::Renderer::EarthquakeHandler
  include Rss::WeatherXml::Renderer::CommentHandler

  template_variable_handler(:kind_name, :template_variable_handler_kind_name)
  template_variable_handler(:area_names, :template_variable_handler_area_names)

  private
    def title_template
      I18n.t('rss.templates.landslide.title')
    end

    def upper_html_template
      I18n.t('rss.templates.landslide.upper_html')
    end

    def loop_html_template
      I18n.t('rss.templates.landslide.loop_html')
    end

    def lower_html_template
      I18n.t('rss.templates.landslide.lower_html')
    end

    def render_loop_html(template)
      text = ''
      REXML::XPath.match(@context.xmldoc, '/Report/Head/Headline/Information[@type="土砂災害警戒情報"]/Item').each do |item|
        xpath = 'Areas[@codeType="気象・地震・火山情報／市町村等"]/Area/Code/text()'
        area_codes = REXML::XPath.match(item, xpath).map { |code| code.to_s.strip }
        # 土砂災害警戒情報の area_code はなぜか先頭に 0 がつくので削除する
        area_codes = normalize_area_codes(area_codes)
        area_codes = @context.area_codes & area_codes
        next if area_codes.blank?

        text << render_template(template, item, area_codes)
        text << "\n"
      end
      text
    end

    def normalize_area_codes(area_codes)
      area_codes.map { |area_code| normalize_area_code(area_code) }
    end

    def normalize_area_code(area_code)
      if area_code.start_with?('0') && area_code.length == 7
        area_code[1..-1]
      else
        area_code
      end
    end

    def template_variable_handler_kind_name(name, xml_node, *_)
      REXML::XPath.first(xml_node, 'Kind/Name/text()').to_s.strip
    end

    def template_variable_handler_area_names(name, xml_node, area_codes, *_)
      areas = REXML::XPath.match(xml_node, 'Areas[@codeType="気象・地震・火山情報／市町村等"]/Area').select do |area|
        area_codes.include?(normalize_area_code(area.elements['Code'].text.to_s.strip))
      end

      areas.map { |area| area.elements['Name'].text.to_s.strip }.join('、')
    end
end
