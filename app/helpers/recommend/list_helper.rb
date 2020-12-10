module Recommend::ListHelper
  def render_content_list
    cur_item = @cur_part
    cur_item.cur_date = @cur_date

    h = []
    h << cur_item.upper_html.html_safe if cur_item.upper_html.present?

    display_list = []
    displayed = 0
    @items.each do |item|
      next if display_list.index(item.path)
      content = item.content
      next unless content
      next unless content.public?

      display_list << item.path
      displayed += 1
      if cur_item.loop_setting.present?
        ih = item.render_template(cur_item.loop_setting.html, self)
      elsif cur_item.loop_html.present?
        ih = cur_item.render_loop_html(content)
      else
        ih = []
        ih << '<article class="item-#{class}">'
        ih << '  <header>'
        ih << '    <h2><a href="#{url}">#{name}</a></h2>'
        ih << '  </header>'
        ih << '</article>'
        ih = cur_item.render_loop_html(content, html: ih.join("\n"))
      end
      h << ih.gsub('#{current}', current_url?(content.url).to_s)
      break if displayed >= @limit
    end
    h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

    h.join.html_safe
  end
end
