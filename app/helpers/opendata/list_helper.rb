module Opendata::ListHelper
  include Opendata::ListHelpers::Dataset
  include Opendata::ListHelpers::App
  include Opendata::ListHelpers::Idea

  def render_page_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    h = []
    h << cur_item.upper_html.html_safe if cur_item.upper_html.present?
    if block_given?
      h << capture(&block)
    else
      @items.each do |item|
        if cur_item.loop_html.present?
          ih = cur_item.render_loop_html(item)
        else
          ih = []
          ih << '<article class="item-#{class} #{new} #{current}">'
          ih << '  <header>'
          ih << '    <time datetime="#{date.iso}">#{date.long}</time>'
          ih << '    <h2>'
          ih << '      <a href="#{url}">#{name}</a>'
          if item.parent.becomes_with_route.show_point?
            ih << '      <span class="point">#{point}</span>'
          end
          ih << '    </h2>'
          ih << '  </header>'
          ih << '</article>'
          ih = cur_item.render_loop_html(item, html: ih.join("\n"))
        end
        h << ih.gsub('#{current}', current_url?(item.url).to_s)
      end
    end
    h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

    h.join("\n").html_safe
  end
end
