module Recommend::ListHelper
  include Cms::ListHelper

  def render_content_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    h = []
    h << cur_item.upper_html.html_safe if cur_item.upper_html.present?

    display_list = []
    @items = []
    @contents.each do |content|
      content.cur_site = @cur_site if content.respond_to?(:cur_site=) && content.site_id == @cur_site.id
      next if display_list.index(content.path)

      item = content.content
      next unless item
      next unless item.public?

      display_list << content.path
      @items << item
      break if display_list.size >= @limit
    end

    if @items.blank? && cur_item.try(:no_items_display_state) == 'hide'
      return cur_item.substitute_html.to_s.html_safe
    end

    if cur_item.loop_format_shirasagi?
      render_list_with_shirasagi(cur_item, default_page_loop_html, &block)
    else
      source = cur_item.loop_liquid.presence || default_page_loop_liquid
      assigns = { "pages" => @items.to_a }
      render_list_with_liquid(source, assigns)
    end
  end
end
