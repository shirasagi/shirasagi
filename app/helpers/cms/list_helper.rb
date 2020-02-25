module Cms::ListHelper
  def default_node_loop_html
    ih = []
    ih << '<article class="item-#{class} #{current}">'
    ih << '  <header>'
    ih << '     <h2><a href="#{url}">#{name}</a></h2>'
    ih << '  </header>'
    ih << '</article>'
    ih.join("\n").freeze
  end

  def default_node_loop_liquid
    ih = []
    ih << '{% for node in nodes %}'
    ih << '<article class="item-{{ node.css_class }} {% if node.current? %}current{% endif %}">'
    ih << '  <header>'
    ih << '     <h2><a href="{{ node.url }}">{{ node.name }}</a></h2>'
    ih << '  </header>'
    ih << '</article>'
    ih << '{% endfor %}'
    ih.join("\n").freeze
  end

  def default_page_loop_html
    ih = []
    ih << '<article class="item-#{class} #{new} #{current}">'
    ih << '  <header>'
    ih << '    <time datetime="#{date.iso}">#{date.long}</time>'
    ih << '    <h2><a href="#{url}">#{index_name}</a></h2>'
    ih << '  </header>'
    ih << '</article>'
    ih.join("\n").freeze
  end

  def default_page_loop_liquid
    ih = []
    ih << '{% for page in pages %}'
    ih << '<article class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">'
    ih << '  <header>'
    ih << '    <time datetime="{{ page.date }}">{{ page.date | ss_date: "long" }}</time>'
    ih << '    <h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2>'
    ih << '  </header>'
    ih << '</article>'
    ih << '{% endfor %}'
    ih.join("\n").freeze
  end

  def render_node_list(&block)
    cur_item = @cur_part || @cur_node
    if @items.blank? && cur_item.try(:no_items_display_state) == 'hide'
      return cur_item.substitute_html.to_s.html_safe
    end
    cur_item.cur_date = @cur_date

    if cur_item.loop_format_shirasagi?
      render_list_with_shirasagi(cur_item, default_node_loop_html, &block)
    else
      source = cur_item.loop_liquid.presence || default_node_loop_liquid
      assigns = { "nodes" => @items.to_a.map(&:becomes_with_route) }
      render_list_with_liquid(source, assigns)
    end
  end

  def render_page_list(&block)
    cur_item = @cur_part || @cur_node
    if @items.blank? && cur_item.try(:no_items_display_state) == 'hide'
      return cur_item.substitute_html.to_s.html_safe
    end
    cur_item.cur_date = @cur_date

    if cur_item.loop_format_shirasagi?
      render_list_with_shirasagi(cur_item, default_page_loop_html, &block)
    else
      source = cur_item.loop_liquid.presence || default_page_loop_liquid
      assigns = { "pages" => @items.to_a.map(&:becomes_with_route) }
      render_list_with_liquid(source, assigns)
    end
  end

  private

  def render_list_with_shirasagi(cur_item, default_loop_html, &block)
    h = []

    h << cur_item.upper_html.html_safe if cur_item.upper_html.present?
    if block_given?
      h << capture(&block)
    else
      h << cur_item.substitute_html.to_s.html_safe if @items.blank?
      if cur_item.loop_setting.present?
        loop_html = cur_item.loop_setting.html
      elsif cur_item.loop_html.present?
        loop_html = cur_item.loop_html
      else
        loop_html = default_loop_html
      end

      @items.each do |item|
        ih = cur_item.render_loop_html(item, html: loop_html)
        ih.gsub!('#{current}', current_url?(item.url).to_s)
        h << ih
      end
    end
    h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

    h.join("\n").html_safe
  end

  def render_list_with_liquid(source, assigns)
    template = ::Cms.parse_liquid(source, liquid_registers)

    if @cur_part
      assigns["part"] = @cur_part
    end
    if @cur_node
      assigns["node"] = @cur_node
    end

    template.render(assigns).html_safe
  end
end
