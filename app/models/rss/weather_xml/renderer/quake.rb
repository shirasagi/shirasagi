class Rss::WeatherXml::Renderer::Quake < Rss::WeatherXml::Renderer::Base
  include Rss::WeatherXml::Renderer::ControlHandler
  include Rss::WeatherXml::Renderer::HeadHandler
  include Rss::WeatherXml::Renderer::EarthquakeHandler
  include Rss::WeatherXml::Renderer::CommentHandler

  template_variable_handler(:pref_name, :template_variable_handler_pref_name)
  template_variable_handler(:pref_code, :template_variable_handler_pref_code)
  template_variable_handler(:area_name, :template_variable_handler_area_name)
  template_variable_handler(:area_code, :template_variable_handler_area_code)
  template_variable_handler(:intensity, :template_variable_handler_intensity_label)
  template_variable_handler(:intensity_label, :template_variable_handler_intensity_label)
  template_variable_handler(:forecast_comment, :template_variable_handler_forecast_comment)

  private
    def title_template
      I18n.t('rss.templates.quake.title')
    end

    def upper_html_template
      I18n.t('rss.templates.quake.upper_html')
    end

    def loop_html_template
      I18n.t('rss.templates.quake.loop_html')
    end

    def lower_html_template
      I18n.t('rss.templates.quake.lower_html')
    end

    def render_loop_html(template)
      text = ''
      @context.region_eq_infos.each do |cur_info|
        text << render_template(template, cur_info)
        text << "\n"
      end
      text
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
end
