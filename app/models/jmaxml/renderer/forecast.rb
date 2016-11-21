class Jmaxml::Renderer::Forecast < Jmaxml::Renderer::Base
  include Jmaxml::Renderer::ControlHandler
  include Jmaxml::Renderer::HeadHandler
  include Jmaxml::Renderer::EarthquakeHandler
  include Jmaxml::Renderer::CommentHandler

  template_variable_handler(:area_name, :template_variable_handler_area_name)
  template_variable_handler(:area_code, :template_variable_handler_area_code)
  template_variable_handler(:kind_names, :template_variable_handler_kind_names)

  private
    def title_template
      I18n.t('jmaxml.templates.forecase.title')
    end

    def upper_html_template
      I18n.t('jmaxml.templates.forecase.upper_html')
    end

    def loop_html_template
      I18n.t('jmaxml.templates.forecase.loop_html')
    end

    def lower_html_template
      I18n.t('jmaxml.templates.forecase.lower_html')
    end

    def render_loop_html(template)
      text = ''
      REXML::XPath.match(@context.xmldoc, '/Report/Body/Warning[@type="気象警報・注意報（市町村等）"]/Item').each do |item|
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

    def template_variable_handler_area_code(name, xml_node, *_)
      REXML::XPath.first(xml_node, 'Area/Code/text()').to_s.strip
    end

    def template_variable_handler_kind_names(name, xml_node, *_)
      names = REXML::XPath.match(xml_node, 'Kind').map do |kind|
        kind_name = kind.elements['Name'].text.to_s.strip
        kind_status = kind.elements['Status'].text.to_s.strip
        kind_status == '解除' ? "#{kind_name}#{kind_status}" : kind_name
      end
      names.join("、")
    end
end
