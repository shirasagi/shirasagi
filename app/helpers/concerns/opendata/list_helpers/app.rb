module Opendata::ListHelpers::App
  extend ActiveSupport::Concern

  def default_app_upper_html
    app_node = Opendata::Node::App.site(@cur_site).and_public.first
    show_point = app_node.show_point?

    h = []
    h << '<table class="opendata-datasets index">'
    h << '<thead>'
    h << '<tr>'
    h << "  <th class=\"name\">#{I18n.t('opendata.labels.app_name')}</th>"
    h << "  <th class=\"updated\">#{I18n.t('opendata.labels.update_datetime')}</th>"
    h << "  <th class=\"state\">#{I18n.t('opendata.labels.state')}</th>"
    if show_point
      h << "  <th class=\"point\">#{I18n.t('opendata.labels.point')}</th>"
    end
    h << '</tr>'
    h << '</thead>'
    h << '<tbody>'

    h.join("\n")
  end

  def default_app_lower_html
    h = []
    h << '</tbody>'
    h << '</table>'
    h.join("\n")
  end

  def render_app_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    app_node = Opendata::Node::App.site(@cur_site).and_public.first
    show_point = app_node.show_point?

    h = []
    h << cur_item.upper_html.presence || default_app_upper_html

    if block_given?
      h << capture(&block)
    else
      @items.each do |item|
        if cur_item.loop_html.present?
          ih = cur_item.render_loop_html(item)
        else
          ih = []
          ih << '<tr>'
          ih << '  <td><a href="#{app_url}">#{app_name}</a></td>'
          ih << '  <td>#{app_updated}</td>'
          ih << '  <td>#{app_state}</td>'
          if show_point
            ih << '  <td>#{app_point}</td>'
          end
          ih << '</tr>'
          ih = cur_item.render_loop_html(item, html: ih.join("\n"))
        end
        h << ih.gsub('#{current}', current_url?(item.url).to_s)
      end
    end

    h << cur_item.lower_html.presence || default_app_lower_html

    h.join("\n").html_safe
  end
end
