module Inquiry::ListHelper
  include Cms::ListHelper

  def default_table_html
    ih = []
    ih << "<table id=\"forms\">"
    ih << "<caption>#{@cur_node.name}</caption>"
    ih << "<thead>"
    ih << "<tr>"
    ih << "<th>#{@cur_node.class.t :name}</th>"
    ih << "<th>#{t "inquiry.reception_plan"}</th>"
    show_aggregation = @items.map(&:aggregation_enabled?).index(true)
    if show_aggregation
      ih << "<th>#{t "inquiry.aggregate"}</th>"
    end
    ih << "</tr>"
    ih << "</thead>"
    ih << "<tbody>"
    @items.each do |item|
      ih << "<tr>"
      ih << "<td>"
      name = item.index_name.presence || item.name
      if item.reception_enabled?
        ih << "#{link_to name, item.url}"
      else
        ih << "#{name}"
      end
      ih << "</td>"
      ih << "<td>"
      if item.reception_start_date.present?
        ih << "#{item.reception_start_date.strftime(t("date.formats.long"))}"
        ih << "#{t "inquiry.from"}"
        ih << "#{item.reception_close_date.strftime(t("date.formats.long"))}"
      end
      ih << "</td>"
      if show_aggregation
        ih << "<td>"
        if item.aggregation_enabled?
          ih << "#{link_to t("inquiry.aggregate"), "#{item.url}results.html"}"
        else
          ih << "#{t("inquiry.aggregate")}"
        end
        ih << "</td>"
      end
      ih << "</tr>"
    end
    ih << "</tbody>"
    ih << "</table>"
    ih.join("\n").freeze
  end

  def render_inquiry_list(&block)
    cur_item = @cur_part || @cur_node
    if @items.blank? && cur_item.try(:no_items_display_state) == 'hide'
      return cur_item.substitute_html.to_s.html_safe
    end
    cur_item.cur_date = @cur_date

    if cur_item.loop_format_shirasagi?
      render_list_with_shirasagi(cur_item, default_table_html, &block)
    else
      source = cur_item.loop_liquid.presence || default_table_html
      assigns = { "nodes" => @items.to_a.map(&:becomes_with_route) }
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
