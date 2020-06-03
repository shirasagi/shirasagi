module Garbage::ListHelper
  include Cms::ListHelper

  def default_table_html
    ih = []
    ih << @cur_node.upper_html
    ih << "<table class=\"columns\">"
    ih << "  <caption>#{@cur_node.name}</caption>"
    ih << "  <thead>"
    ih << "    <tr>"
    ih << "      <th>#{t('garbage.item')}</th>"
    ih << "      <th>#{t('garbage.category.name')}</th>"
    ih << "      <th>#{t('garbage.remark')}</th>"
    ih << "    </tr>"
    ih << "  </thead>"
    ih << "  <tbody>"

    @items.each do |item|
      name = item.index_name.presence || item.name
      ih << "<tr>"
      ih << "  <td>#{link_to(name, item.url)}</td>"
      ih << "  <td>#{br(item.categories.map(&:name).join("\n"))}</td>"
      ih << "  <td>#{item.remark}</td>"
      ih << "</tr>"
    end

    ih << "  </tbody>"
    ih << "</table>"
    ih << @cur_node.lower_html
    ih.join("\n").html_safe
  end

  def blank_items_html
    ih = []

    if @cur_node.no_items_display_state != 'hide'
      ih << @cur_node.upper_html
      ih << @cur_node.substitute_html
      ih << @cur_node.lower_html
    else
      ih << @cur_node.substitute_html
    end

    ih.join("\n").html_safe
  end

  def render_garbage_list(&block)
    @cur_node.cur_date = @cur_date

    return blank_items_html if @items.blank?

    if @cur_node.loop_format_shirasagi?
      loop_html = @cur_node.loop_html
      loop_html = @cur_node.loop_setting.html if @cur_node.loop_setting.present?

      return default_table_html if loop_html.blank?

      render_list_with_shirasagi(@cur_node, "", &block)
    else
      loop_html = @cur_node.loop_liquid

      return default_table_html if loop_html.blank?

      assigns = { "nodes" => @items.to_a }
      render_list_with_liquid(loop_html, assigns)
    end
  end
end
