class Jmaxml::Renderer::Flood < Jmaxml::Renderer::Base
  include Jmaxml::Renderer::ControlHandler
  include Jmaxml::Renderer::HeadHandler
  include Jmaxml::Renderer::EarthquakeHandler
  include Jmaxml::Renderer::CommentHandler

  template_variable_handler(:river_name, :template_variable_handler_river_name)
  template_variable_handler(:kind_name, :template_variable_handler_kind_name)
  template_variable_handler(:kind_condition, :template_variable_handler_kind_condition)
  template_variable_handler(:main_sentence, :template_variable_handler_main_sentence)
  template_variable_handler(:station_name, :template_variable_handler_station_name)
  template_variable_handler(:station_location, :template_variable_handler_station_location)
  template_variable_handler(:rainfall_text, :template_variable_handler_rainfall_text)

  private
    def title_template
      I18n.t('jmaxml.templates.flood.title')
    end

    def upper_html_template
      I18n.t('jmaxml.templates.flood.upper_html')
    end

    def loop_html_template
      I18n.t('jmaxml.templates.flood.loop_html')
    end

    def lower_html_template
      I18n.t('jmaxml.templates.flood.lower_html')
    end

    def render_loop_html(template)
      text = ''
      REXML::XPath.match(@context.xmldoc, '/Report/Body/Warning[@type="指定河川洪水予報"]/Item').each do |item|
        area_code = REXML::XPath.match(item, 'Stations/Station/Code[@type="水位観測所"]/text()').first do |area_code|
          area_code = area_code.to_s.strip
          @context.area_codes.include?(area_code)
        end
        next if area_code.blank?

        text << render_template(template, item)
        text << "\n"
      end
      text
    end

    def template_variable_handler_river_name(name, xml_node, *_)
      REXML::XPath.first(xml_node, 'Areas[@codeType="河川"]/Area/Name/text()').to_s.strip
    end

    def template_variable_handler_kind_name(name, xml_node, *_)
      river_codes = REXML::XPath.match(xml_node, 'Areas[@codeType="河川"]/Area/Code/text()').map { |code| code.to_s.strip }
      item = REXML::XPath.match(@context.xmldoc, '/Report/Head/Headline/Information[@type="指定河川洪水予報（河川）"]/Item').first do |item|
        item_river_codes = REXML::XPath.match(item, 'Areas[@codeType="河川"]/Area/Code/text()').map { |code| code.to_s.strip }
        (river_codes - item_river_codes).present?
      end
      REXML::XPath.first(item, 'Kind/Name/text()').to_s.strip
    end

    def template_variable_handler_kind_condition(name, xml_node, *_)
      river_codes = REXML::XPath.match(xml_node, 'Areas[@codeType="河川"]/Area/Code/text()').map { |code| code.to_s.strip }
      item = REXML::XPath.match(@context.xmldoc, '/Report/Head/Headline/Information[@type="指定河川洪水予報（河川）"]/Item').first do |item|
        item_river_codes = REXML::XPath.match(item, 'Areas[@codeType="河川"]/Area/Code/text()').map { |code| code.to_s.strip }
        (river_codes - item_river_codes).present?
      end
      REXML::XPath.first(item, 'Kind/Condition/text()').to_s.strip
    end

    def template_variable_handler_main_sentence(name, xml_node, *_)
      property = REXML::XPath.match(xml_node, 'Kind/Property').first do |property|
        type = REXML::XPath.first(property, 'Type/text()').to_s.strip
        type == '主文'
      end
      return if property.blank?

      REXML::XPath.first(property, 'Text/text()').to_s.strip
    end

    def template_variable_handler_station_name(name, xml_node, *_)
      REXML::XPath.first(xml_node, 'Stations/Station/Name/text()').to_s.strip
    end

    def template_variable_handler_station_location(name, xml_node, *_)
      REXML::XPath.first(xml_node, 'Stations/Station/Location/text()').to_s.strip
    end

    def template_variable_handler_rainfall_text(*_)
      ret = ''
      xpath = '/Report/Body/MeteorologicalInfos[@type="雨量情報"]/MeteorologicalInfo/Item/Kind/Property'
      REXML::XPath.match(@context.xmldoc, xpath).each do |property|
        ret << property.elements['Text'].text.to_s.strip if property.elements['Type'].text.to_s.strip == '雨量'
      end
      ret
    end
end
