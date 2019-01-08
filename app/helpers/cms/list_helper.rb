module Cms::ListHelper
  DEFAULT_NODE_LOOP_HTML = begin
    ih = []
    ih << '<article class="item-#{class} #{current}">'
    ih << '  <header>'
    ih << '     <h2><a href="#{url}">#{name}</a></h2>'
    ih << '  </header>'
    ih << '</article>'
    ih.join("\n").freeze
  end

  DEFAULT_NODE_LOOP_LIQUID = begin
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

  DEFAULT_PAGE_LOOP_HTML = begin
    ih = []
    ih << '<article class="item-#{class} #{new} #{current}">'
    ih << '  <header>'
    ih << '    <time datetime="#{date.iso}">#{date.long}</time>'
    ih << '    <h2><a href="#{url}">#{index_name}</a></h2>'
    ih << '  </header>'
    ih << '</article>'
    ih.join("\n").freeze
  end

  DEFAULT_PAGE_LOOP_LIQUID = begin
    ih = []
    ih << '{% for page in pages %}'
    ih << '<article class="item-{{ page.css_class }} {% if page.new? %}new{% endif %} {% if page.current? %}current{% endif %}">'
    ih << '  <header>'
    ih << '    <time datetime="{{ page.date }}">{{ page.date | ss_date: "long" }}</time>'
    ih << '    <h2><a href="{{ page.url }}">{{ page.index_name }}</a></h2>'
    ih << '  </header>'
    ih << '</article>'
    ih << '{% endfor %}'
    ih.join("\n").freeze
  end

  def render_node_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    if cur_item.loop_format_shirasagi?
      h = []

      h << cur_item.upper_html.html_safe if cur_item.upper_html.present?
      if block_given?
        h << capture(&block)
      else
        @items.each do |item|
          if cur_item.loop_setting.present?
            ih = item.render_template(cur_item.loop_setting.html, self)
          elsif cur_item.loop_html.present?
            ih = cur_item.render_loop_html(item)
          else
            ih = cur_item.render_loop_html(item, html: Cms::ListHelper::DEFAULT_NODE_LOOP_HTML)
          end
          h << ih.gsub('#{current}', current_url?(item.url).to_s)
        end
      end
      h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

      h.join.html_safe
    else
      template = Liquid::Template.parse(cur_item.loop_liquid.presence || DEFAULT_NODE_LOOP_LIQUID)

      render_opts = { "nodes" => @items.to_a.map(&:becomes_with_route), "parts" => SS::LiquidPartDrop.new(@cur_site) }
      if @cur_part
        render_opts["part"] = @cur_part
      end
      if @cur_node
        render_opts["node"] = @cur_node
      end

      registers = {
        preview: @preview,
        mobile: controller.filters.include?(:mobile),
        cur_site: @cur_site,
        cur_part: @cur_part,
        cur_node: @cur_node,
        cur_page: @cur_page,
        cur_path: @cur_path,
        cur_date: @cur_date,
        cur_main_path: @cur_main_path
      }
      template.render(render_opts, { filters: [SS::LiquidFilters], registers: registers }).html_safe
    end
  end

  def render_page_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    if cur_item.loop_format_shirasagi?
      h = []
      h << cur_item.upper_html.html_safe if cur_item.upper_html.present?
      if block_given?
        h << capture(&block)
      else
        @items.each do |item|
          if cur_item.loop_setting.present?
            ih = item.render_template(cur_item.loop_setting.html, self)
          elsif cur_item.loop_html.present?
            ih = cur_item.render_loop_html(item)
          else
            ih = cur_item.render_loop_html(item, html: Cms::ListHelper::DEFAULT_PAGE_LOOP_HTML)
          end
          h << ih.gsub('#{current}', current_url?(item.url).to_s)
        end
      end
      h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

      h.join("\n").html_safe
    else
      template = Liquid::Template.parse(cur_item.loop_liquid.presence || DEFAULT_PAGE_LOOP_LIQUID)

      render_opts = { "pages" => @items.to_a.map(&:becomes_with_route), "parts" => SS::LiquidPartDrop.new(@cur_site) }
      if @cur_part
        render_opts["part"] = @cur_part
      end
      if @cur_node
        render_opts["node"] = @cur_node
      end

      registers = {
        preview: @preview,
        mobile: controller.filters.include?(:mobile),
        cur_site: @cur_site,
        cur_part: @cur_part,
        cur_node: @cur_node,
        cur_page: @cur_page,
        cur_path: @cur_path,
        cur_date: @cur_date,
        cur_main_path: @cur_main_path
      }
      template.render(render_opts, { filters: [SS::LiquidFilters], registers: registers }).html_safe
    end
  end
end
