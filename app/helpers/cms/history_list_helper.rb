module Cms::HistoryListHelper
  include Cms::ListHelper

  def default_upper_html
    ih = []
    ih << '<section id="history">'
    ih << "<header><h2>#{I18n.t("cms.parts.cms/history_list")}</h2></header>"
    ih << '<ul>'
    ih.join("\n").freeze
  end

  def default_lower_html
    ih = []
    ih << '</ul>'
    ih << '</section>'
    ih.join("\n").freeze
  end

  def default_loop_html
    ih = []
    ih << '<li class="current"><a href="#{url}">#{index_name}</a></li>'
    ih.join("\n").freeze
  end

  def default_loop_liquid
    ih = []
    ih << '<section id="history">'
    ih << "<header><h2>#{I18n.t("cms.parts.cms/history_list")}</h2></header>"
    ih << '<ul>'
    ih << '{% for item in items %}'
    ih << '<li class="current"><a href="{{ item.url }}">{{ item.index_name | default: item.name }}</a></li>'
    ih << '{% endfor %}'
    ih << '</ul>'
    ih << '</section>'
    ih.join("\n").freeze
  end

  def render_item_list
    return unless @item

    # @item is page or node only
    @items = [@item]
    @items = [] if controller.preview_path?

    cur_item = @cur_part
    cur_item.cur_date = @cur_date
    cur_item.upper_html = default_upper_html if cur_item.upper_html.blank?
    cur_item.lower_html = default_lower_html if cur_item.lower_html.blank?

    if cur_item.loop_format_shirasagi?
      render_list_with_shirasagi(cur_item, default_loop_html)
    else
      source = cur_item.loop_liquid.presence || default_loop_liquid
      assigns = { "items" => @items }
      render_list_with_liquid(source, assigns)
    end
  end
end
