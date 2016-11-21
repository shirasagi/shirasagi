class Jmaxml::Renderer::AshFall < Jmaxml::Renderer::Base
  include Jmaxml::Renderer::ControlHandler
  include Jmaxml::Renderer::HeadHandler
  include Jmaxml::Renderer::EarthquakeHandler
  include Jmaxml::Renderer::CommentHandler
  include Jmaxml::Renderer::VolcanoHandler

  template_variable_handler(:kind_name, :template_variable_handler_kind_name)
  template_variable_handler(:area_names, :template_variable_handler_area_names)

  private
    def title_template
      I18n.t('jmaxml.templates.ash_fall.title')
    end

    def upper_html_template
      I18n.t('jmaxml.templates.ash_fall.upper_html')
    end

    def loop_html_template
      I18n.t('jmaxml.templates.ash_fall.loop_html')
    end

    def lower_html_template
      I18n.t('jmaxml.templates.ash_fall.lower_html')
    end

    def render_loop_html(template)
      text = ''
      REXML::XPath.match(@context.xmldoc, '/Report/Body/VolcanoInfo[@type="降灰予報（対象市町村等）"]/Item').each do |item|
        xpath = 'Areas[@codeType="気象・地震・火山情報／市町村等"]/Area/Code/text()'
        area_codes = REXML::XPath.match(item, xpath).map { |c| c.to_s.strip }
        next unless area_codes.first { |area_code| @context.area_codes.include?(area_code) }

        text << render_template(template, item)
        text << "\n"
      end
      text
    end

    def template_variable_handler_kind_name(name, xml_node, *_)
      REXML::XPath.first(xml_node, 'Kind/Name/text()').to_s.strip
    end

    def template_variable_handler_area_names(name, xml_node, *_)
      area_names = REXML::XPath.match(xml_node, 'Areas[@codeType="気象・地震・火山情報／市町村等"]/Area').map do |area|
        area_code = area.elements['Code'].text.to_s.strip
        next nil unless @context.area_codes.include?(area_code)

        area.elements['Name'].text.to_s.strip
      end

      area_names.compact.join("、")
    end
end
