class Rss::WeatherXml::Renderer::Base
  include SS::TemplateVariable

  attr_reader :page, :context

  def initialize(page, context)
    @page = page
    @context = context
  end

  def render_title(options = {})
    template = normalize_template(options[:template].presence || title_template)
    return if template.blank?

    render_template(template)
  end

  def render_html(options = {})
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

  private
    def normalize_template(template)
      template = template.join("\n") if template.is_a?(Array)
      template
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
end
