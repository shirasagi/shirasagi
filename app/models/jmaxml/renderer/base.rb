class Jmaxml::Renderer::Base
  include SS::TemplateVariable

  attr_reader :page, :context

  def initialize(page, context)
    @page = page
    @context = context
  end

  def render_title(options = {})
    template = normalize_template(options[:template].presence || title_template)
    return if template.blank?

    status = control_status
    status_template = I18n.t('jmaxml.templates.status') if status != '通常'
    info_type = head_info_type
    info_type_template = I18n.t('jmaxml.templates.info_type') if info_type == '取消'

    template = "#{status_template}#{info_type_template}#{template}"

    render_template(template)
  end

  def render_html(options = {})
    if head_info_type == '取消'
      cancel_template = normalize_template(options[:cancel_template].presence || cancel_html_template)
      return render_template(cancel_template)
    end

    upper_template = normalize_template(options[:upper_template].presence || upper_html_template)
    loop_template = normalize_template(options[:loop_template].presence || loop_html_template)
    lower_template = normalize_template(options[:lower_template].presence || lower_html_template)

    text = ''
    if upper_template.present?
      text = render_template(upper_template)
      text << "\n\n"
    end
    if loop_template.present?
      text << render_loop_html(loop_template)
      text << "\n"
    end
    if lower_template.present?
      text << render_template(lower_template)
      text << "\n"
    end
    text
  end

  def render_text(options = {})
    if head_info_type == '取消'
      cancel_template = normalize_template(options[:cancel_template].presence || cancel_text_template)
      return render_template(cancel_template) << "\n"
    end

    upper_template = normalize_template(options[:upper_template].presence || upper_text_template)
    loop_template = normalize_template(options[:loop_template].presence || loop_text_template)
    lower_template = normalize_template(options[:lower_template].presence || lower_text_template)

    text = ''
    if upper_template.present?
      text = render_template(upper_template)
      text << "\n\n"
    end
    if loop_template.present?
      text << render_loop_html(loop_template)
      text << "\n"
    end
    if lower_template.present?
      text << render_template(lower_template)
      text << "\n"
    end
    text
  end

  private
    def normalize_template(template)
      if template.is_a?(Array)
        template.join("\n")
      else
        template
      end
    end

    def title_template
      raise NotImplementedError
    end

    def upper_html_template
      raise NotImplementedError
    end

    def loop_html_template
      raise NotImplementedError
    end

    def lower_html_template
      raise NotImplementedError
    end

    def render_loop_html(template)
      raise NotImplementedError
    end

    def cancel_html_template
      I18n.t('jmaxml.templates.cancel_html')
    end

    def upper_text_template
      raise NotImplementedError
    end

    def loop_text_template
      raise NotImplementedError
    end

    def lower_text_template
      raise NotImplementedError
    end

    def render_loop_text(template)
      render_loop_html(template)
    end

    def cancel_text_template
      I18n.t('jmaxml.templates.cancel_text')
    end
end
