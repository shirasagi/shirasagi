module Inquiry::ListHelper
  include Cms::ListHelper

  def default_page_loop_html
    render partial: 'inquiry/agents/nodes/node/default_node_loop_html'
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

      if loop_html == default_loop_html
        h << default_loop_html
      else
        @items.each do |item|
          ih = cur_item.render_loop_html(item, html: loop_html)
          ih.gsub!('#{current}', current_url?(item.url).to_s)
          h << ih
        end
      end
    end
    h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

    h.join("\n").html_safe
  end
end
