class Rss::WeatherXml::Renderer::Quake
  include SS::TemplateVariable

  template_variable_handler(:status, :template_variable_handler_status)
  template_variable_handler(:status_label, :template_variable_handler_status_label)
  template_variable_handler(:target_time, :template_variable_handler_target_time)
  template_variable_handler(:pref_name, :template_variable_handler_pref_name)
  template_variable_handler(:pref_code, :template_variable_handler_pref_code)
  template_variable_handler(:area_name, :template_variable_handler_area_name)
  template_variable_handler(:area_code, :template_variable_handler_area_code)
  template_variable_handler(:intensity, :template_variable_handler_intensity_label)
  template_variable_handler(:intensity_label, :template_variable_handler_intensity_label)
  template_variable_handler(:forecast_comment, :template_variable_handler_forecast_comment)
  template_variable_handler(:hypocenter_area_name, :template_variable_handler_hypocenter_area_name)
  template_variable_handler(:hypocenter_area_coordinate, :template_variable_handler_hypocenter_area_coordinate)
  template_variable_handler(:magnitude, :template_variable_handler_magnitude)

  def initialize(page, context)
    @page = page
    @context = context
  end

  def render_title(options = {})
    template = options[:template].presence || I18n.t('rss.templates.quake.title')
    return if template.blank?

    render_template(template)
  end

  def render_html(options = {})
    upper_template = options[:upper_template].presence || I18n.t('rss.templates.quake.upper_html')
    loop_template = options[:loop_template].presence || I18n.t('rss.templates.quake.loop_html')
    lower_template = options[:lower_template].presence || I18n.t('rss.templates.quake.lower_html')

    text = ''
    if upper_template.present?
      text = render_template(upper_template)
      text << "\n\n"
    end
    if loop_template.present?
      @context.region_eq_infos.each do |cur_info|
        text << render_template(loop_template, cur_info)
        text << "\n"
      end
      text << "\n"
    end
    if lower_template.present?
      text << render_template(lower_template)
      text << "\n"
    end
    text
  end

  private
    def target_status
      REXML::XPath.first(@context.xmldoc, '/Report/Control/Status/text()').to_s.strip.presence
    end

    def target_datetime
      target_datetime = REXML::XPath.first(@context.xmldoc, '/Report/Head/TargetDateTime/text()').to_s.strip
      if target_datetime.present?
        target_datetime = Time.zone.parse(target_datetime) rescue nil
      end
      target_datetime
    end

    def forecast_comment
      comment = ''

      REXML::XPath.each(@context.xmldoc, '/Report/Body/Comments/ForecastComment[@codeType="固定付加文"]') do |forecast_comment|
        c = REXML::XPath.first(forecast_comment, 'Text/text()').to_s.strip.presence
        comment << "\n" if comment.present?
        comment << c if c.present?
      end

      comment
    end

    def hypocenter_area_name
      REXML::XPath.first(@context.xmldoc, '/Report/Body/Earthquake/Hypocenter/Area/Name/text()').to_s.strip.presence
    end

    def hypocenter_area_coordinate
      coordinate = REXML::XPath.first(@context.xmldoc, '/Report/Body/Earthquake/Hypocenter/Area/jmx_eb:Coordinate')
      return if coordinate.blank?

      coordinate.attributes['description'].to_s.strip.presence
    end

    def magnitude
      REXML::XPath.first(@context.xmldoc, '/Report/Body/Earthquake/jmx_eb:Magnitude/text()').to_s.strip.presence
    end

    def template_variable_handler_status(*_)
      status
    end

    def template_variable_handler_status_label(*_)
      s = status
      "【#{s}】" if s.present?
    end

    def template_variable_handler_target_time(*_)
      I18n.l(target_datetime, format: :long)
    end

    def template_variable_handler_pref_name(name, cur_info, *_)
      cur_info[:pref_name]
    end

    def template_variable_handler_pref_code(name, cur_info, *_)
      cur_info[:pref_code]
    end

    def template_variable_handler_area_name(name, cur_info, *_)
      cur_info[:area_name]
    end

    def template_variable_handler_area_code(name, cur_info, *_)
      cur_info[:area_code]
    end

    def template_variable_handler_intensity(name, cur_info, *_)
      cur_info[:area_max_int]
    end

    def template_variable_handler_intensity_label(name, cur_info, *_)
      I18n.t("rss.options.earthquake_intensity.#{cur_info[:area_max_int]}", default: cur_info[:area_max_int])
    end

    def template_variable_handler_forecast_comment(*_)
      forecast_comment
    end

    def template_variable_handler_hypocenter_area_name(*_)
      hypocenter_area_name
    end

    def template_variable_handler_hypocenter_area_coordinate(*_)
      hypocenter_area_coordinate
    end

    def template_variable_handler_magnitude(*_)
      magnitude
    end
end
