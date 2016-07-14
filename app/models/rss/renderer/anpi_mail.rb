class Rss::Renderer::AnpiMail
  include ActiveModel::Model
  include SS::TemplateVariable

  attr_accessor :cur_site, :cur_node, :cur_page, :cur_infos

  template_variable_handler(:target_time, :template_variable_handler_target_time)
  template_variable_handler(:anpi_post_url, :template_variable_handler_anpi_post_url)
  template_variable_handler(:pref_name, :template_variable_handler_pref_name)
  template_variable_handler(:area_name, :template_variable_handler_area_name)
  template_variable_handler(:intensity_label, :template_variable_handler_intensity_label)

  def render(*args)
    if cur_node.upper_mail_text.present?
      text = render_template(cur_node.upper_mail_text, *args)
      text << "\n\n"
    end
    if cur_node.loop_mail_text.present?
      @cur_infos[:infos].each do |cur_info|
        @cur_info = cur_info
        text << render_template(cur_node.loop_mail_text, *args)
        text << "\n"
      end
      text << "\n"
    end
    if cur_node.lower_mail_text.present?
      text << render_template(cur_node.lower_mail_text, *args)
      text << "\n"
    end
    text
  end

  private
    def template_variable_handler_target_time(*_)
      I18n.l(@cur_infos[:target_time], format: :long)
    end

    def template_variable_handler_anpi_post_url(*_)
      @cur_node.my_anpi_post.full_url
    end

    def template_variable_handler_pref_name(*_)
      @cur_info[:pref_name]
    end

    def template_variable_handler_area_name(*_)
      @cur_info[:area_name]
    end

    def template_variable_handler_intensity_label(*_)
      I18n.t("rss.options.earthquake_intensity.#{@cur_info[:area_max_int]}", default: @cur_info[:area_max_int])
    end
end
