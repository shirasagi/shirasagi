module Opendata::ListHelpers::Dataset
  extend ActiveSupport::Concern

  def default_dataset_upper_html
    dataset_node = Opendata::Node::Dataset.site(@cur_site).and_public.first
    show_point = dataset_node.show_point?

    h = []
    h << '<table class="opendata-datasets index">'
    h << '<thead>'
    h << '<tr>'
    h << "  <th class=\"name\">#{I18n.t('opendata.labels.dataset_name')}</th>"
    h << "  <th class=\"updated\">#{I18n.t('opendata.labels.update_datetime')}</th>"
    h << "  <th class=\"state\">#{I18n.t('opendata.labels.state')}</th>"
    if show_point
      h << "  <th class=\"point\">#{I18n.t('opendata.labels.point')}</th>"
    end
    h << "  <th class=\"downloaded\">#{I18n.t('opendata.labels.downloaded')}</th>"
    if app_enabled?
      h << "  <th class=\"app\">#{I18n.t('opendata.labels.app')}</th>"
    end
    if idea_enabled?
      h << "  <th class=\"idea\">#{I18n.t('opendata.labels.idea')}</th>"
    end
    h << '</tr>'
    h << '</thead>'
    h << '<tbody>'

    h.join("\n")
  end

  def default_dataset_lower_html
    h = []
    h << '</tbody>'
    h << '</table>'
    h.join("\n")
  end

  def render_dataset_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    dataset_node = Opendata::Node::Dataset.site(@cur_site).and_public.first
    show_point = dataset_node.show_point?

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
          ih << '  <td><a href="#{dataset_url}">#{dataset_name}</a></td>'
          ih << '  <td>#{dataset_updated}</td>'
          ih << '  <td>#{dataset_state}</td>'
          if show_point
            ih << '  <td>#{dataset_point}</td>'
          end
          ih << '  <td>#{dataset_downloaded}</td>'
          if app_enabled?
            ih << '  <td>#{dataset_apps_count}</td>'
          end
          if idea_enabled?
            ih << '  <td>#{dataset_ideas_count}</td>'
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
