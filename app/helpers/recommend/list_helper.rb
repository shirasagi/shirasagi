module Recommend::ListHelper
  def render_content_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    h = []
    h << cur_item.upper_html.html_safe if cur_item.upper_html.present?
    display_list = []
    @items.each do |item|
      content = item.content
      next unless content
      next if display_list.index(item.path)

      display_list << item.path
      if cur_item.loop_html.present?
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
      break if display_list.size >= @limit
    end
    h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

    h.join.html_safe
  end
end
