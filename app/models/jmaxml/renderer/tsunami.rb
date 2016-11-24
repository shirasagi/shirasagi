class Jmaxml::Renderer::Tsunami < Jmaxml::Renderer::Base
  include Jmaxml::Renderer::ControlHandler
  include Jmaxml::Renderer::HeadHandler
  include Jmaxml::Renderer::EarthquakeHandler
  include Jmaxml::Renderer::CommentHandler

  template_variable_handler(:area_name, :template_variable_handler_area_name)
  template_variable_handler(:category_name, :template_variable_handler_category_name)
  template_variable_handler(:first_height_label, :template_variable_handler_first_height_label)
  template_variable_handler(:tsunami_height, :template_variable_handler_tsunami_height)

  def title_template
    I18n.t('jmaxml.templates.tsunami.title')
  end

  def upper_html_template
    I18n.t('jmaxml.templates.tsunami.upper_html')
  end

  def loop_html_template
    I18n.t('jmaxml.templates.tsunami.loop_html')
  end

  def lower_html_template
    I18n.t('jmaxml.templates.tsunami.lower_html')
  end

  def upper_text_template
    I18n.t('jmaxml.templates.tsunami.upper_text')
  end

  def loop_text_template
    I18n.t('jmaxml.templates.tsunami.loop_text')
  end

  def lower_text_template
    I18n.t('jmaxml.templates.tsunami.lower_text')
  end

  def info_group_by(target_sub_type)
    REXML::XPath.match(@context.xmldoc, '/Report/Body/Tsunami/Forecast/Item').map do |item|
      area_code = REXML::XPath.first(item, 'Area/Code/text()').to_s.strip
      next nil unless @context.area_codes.include?(area_code)

      kind_code = REXML::XPath.first(item, 'Category/Kind/Code/text()').to_s.strip
      case kind_code
        when '52'
          kind_code = 'special_alert'
        when '51'
          kind_code = 'alert'
        when '62'
          kind_code = 'warning'
        when '71'
          kind_code = 'forecast'
        else
          kind_code = ''
      end
      next nil if kind_code != target_sub_type.to_s

      area_name = REXML::XPath.first(item, 'Area/Name/text()').to_s.strip
      first_wave = template_variable_handler_first_height_label(nil, item)
      height = template_variable_handler_tsunami_height(nil, item)

      { area_name: area_name, first_wave: first_wave, height: height }
    end.compact
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

      condition = first_height.elements['Condition']
      if condition.present?
        return condition.text.to_s.strip
      end

      arrival_time = first_height.elements['ArrivalTime']
      if arrival_time.present?
        arrival_time = Time.zone.parse(arrival_time.text) rescue nil
        return I18n.l(arrival_time, format: :long) if arrival_time.present?
      end
    end

    def template_variable_handler_tsunami_height(name, xml_node, *_)
      tsunami_height = REXML::XPath.first(xml_node, 'MaxHeight/jmx_eb:TsunamiHeight/text()').to_s.strip
      return if tsunami_height.blank?

      "#{tsunami_height}m"
    end
end
