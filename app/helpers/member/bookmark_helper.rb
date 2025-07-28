module Member::BookmarkHelper
  include Cms::ListHelper

  def default_page_loop_html
    ih = []
    ih << '<article class="item-#{class}">'
    ih << '  <header>'
    ih << '    <h2><a href="#{url}">#{name}</a></h2>'
    ih << '    #{cancel_link}'
    ih << '  </header>'
    ih << '</article>'
    ih.join("\n").freeze
  end

  def default_page_loop_liquid
    ih = []
    ih << '{% for page in pages %}'
    ih << '<article class="item-{{ page.css_class }}">'
    ih << '  <header>'
    ih << '    <h2><a href="{{ page.url }}">{{ page.name }}</a></h2>'
    ih << '    {{ page.cancel_link }}'
    ih << '  </header>'
    ih << '</article>'
    ih << '{% endfor %}'
    ih.join("\n").freeze
  end

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
        item.cur_site = @cur_site if item.respond_to?(:cur_site=) && item.site_id == @cur_site.id

        ih = cur_item.render_loop_html(item, html: loop_html)
        ih.gsub!('#{cancel_link}', item.cancel_link(@cur_node, @cur_path)) if item.respond_to?(:cancel_link)
        ih.gsub!('#{current}', current_url?(item.url).to_s) if item.respond_to?(:url)
        h << ih
      end
    end
    h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

    h.join("\n").html_safe
  end
end
