class Jmaxml::Renderer::Volcano < Jmaxml::Renderer::Base
  include Jmaxml::Renderer::ControlHandler
  include Jmaxml::Renderer::HeadHandler
  include Jmaxml::Renderer::EarthquakeHandler
  include Jmaxml::Renderer::CommentHandler
  include Jmaxml::Renderer::VolcanoHandler

  template_variable_handler(:area_name, :template_variable_handler_area_name)

  private
    def title_template
      I18n.t('jmaxml.templates.volcano.title')
    end

    def upper_html_template
      I18n.t('jmaxml.templates.volcano.upper_html')
    end

    def loop_html_template
      I18n.t('jmaxml.templates.volcano.loop_html')
    end

    def lower_html_template
      I18n.t('jmaxml.templates.volcano.lower_html')
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
end
