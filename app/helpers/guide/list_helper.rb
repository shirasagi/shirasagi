module Guide::ListHelper
  def default_procedure_loop_html
    ih = []
    ih << '<dl class="procedure item-#{id}">'
    ih << '  <dt>#{link}</dt>'
    ih << '  <dd>#{html}</dd>'
    ih << '</dl>'
    ih.join("\n").freeze
  end

  def default_procedure_loop_liquid
    ih = []
    ih << '{% for item in procedures %}'
    ih << '<dl class="procedure item-{{ item.id }}">'
    ih << '  <dt>'
    ih << '    {% if item.link_url %}'
    ih << '      <a href="{{ item.link_url }}">{{ item.name }}</a>'
    ih << '    {% else %}'
    ih << '      {{ item.name }}'
    ih << '    {% endif %}'
    ih << '  </dt>'
    ih << '  <dd>{{ item.procedure_location }}</dd>'
    ih << '</dl>'
    ih << '{% endfor %}'
    ih.join("\n").freeze
  end

  def render_procedure_list(items)
    @cur_node.cur_date = @cur_date
    if @cur_node.loop_format_shirasagi?
      render_list_with_shirasagi(items)
    else
      source = @cur_node.loop_liquid.presence || default_procedure_loop_liquid
      assigns = { "procedures" => items.to_a }
      render_list_with_liquid(source, assigns)
    end
  end

  private

  def render_list_with_shirasagi(items)
    h = []

    if @cur_node.loop_setting.present?
      loop_html = @cur_node.loop_setting.html
    elsif @cur_node.loop_html.present?
      loop_html = @cur_node.loop_html
    else
      loop_html = default_procedure_loop_html
    end

    items.each do |item|
      ih = @cur_node.render_loop_html(item, html: loop_html)
      h << ih
    end

    h.join("\n").html_safe
  end

  def render_list_with_liquid(source, assigns)
    template = ::Cms.parse_liquid(source, liquid_registers)
    assigns["node"] = @cur_node
    template.render(assigns).html_safe
  end
end
