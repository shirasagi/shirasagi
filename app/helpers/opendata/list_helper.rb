module Opendata::ListHelper
  def render_page_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    h  = []
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

  def render_dataset_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    dataset_node = Opendata::Node::Dataset.site(@cur_site).and_public.first
    show_point = dataset_node.show_point?

    h  = []
    if cur_item.upper_html.present?
      h << cur_item.upper_html.html_safe
    else
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
    end
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
    if cur_item.lower_html.present?
      h << cur_item.lower_html.html_safe
    else
      h << '</tbody>'
      h << '</table>'
    end

    h.join("\n").html_safe
  end

  def render_app_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    app_node = Opendata::Node::App.site(@cur_site).and_public.first
    show_point = app_node.show_point?

    h  = []
    if cur_item.upper_html.present?
      h << cur_item.upper_html.html_safe
    else
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
    end
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
    if cur_item.lower_html.present?
      h << cur_item.lower_html.html_safe
    else
      h << '</tbody>'
      h << '</table>'
    end

    h.join("\n").html_safe
  end

  def render_idea_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    idea_node = Opendata::Node::Idea.site(@cur_site).and_public.first
    show_point = idea_node.show_point?

    h  = []
    if cur_item.upper_html.present?
      h << cur_item.upper_html.html_safe
    else
      h << '<table class="opendata-datasets index">'
      h << '<thead>'
      h << '<tr>'
      h << "  <th class=\"name\">#{I18n.t('opendata.labels.app_name')}</th>"
      h << "  <th class=\"updated\">#{I18n.t('opendata.labels.update_datetime')}</th>"
      h << "  <th class=\"state\">#{I18n.t('opendata.labels.state')}</th>"
      if show_point
        h << "  <th class=\"point\">#{I18n.t('opendata.labels.point')}</th>"
      end
      if dataset_enabled?
        h << "  <th class=\"dataset\">#{I18n.t('opendata.labels.dataset')}</th>"
      end
      if app_enabled?
        h << "  <th class=\"app\">#{I18n.t('opendata.labels.app')}</th>"
      end
      h << '</tr>'
      h << '</thead>'
      h << '<tbody>'
    end
    if block_given?
      h << capture(&block)
    else
      @items.each do |item|
        if cur_item.loop_html.present?
          ih = cur_item.render_loop_html(item)
        else
          ih = []
          ih << '<tr>'
          ih << '  <td><a href="#{idea_url}">#{idea_name}</a></td>'
          ih << '  <td>#{idea_updated}</td>'
          ih << '  <td>#{idea_state}</td>'
          if show_point
            ih << '  <td>#{idea_point}</td>'
          end
          if dataset_enabled?
            ih << '  <td>#{idea_datasets}</td>'
          end
          if app_enabled?
            ih << '  <td>#{idea_apps}</td>'
          end
          ih << '</tr>'
          ih = cur_item.render_loop_html(item, html: ih.join("\n"))
        end
        h << ih.gsub('#{current}', current_url?(item.url).to_s)
      end
    end
    if cur_item.lower_html.present?
      h << cur_item.lower_html.html_safe
    else
      h << '</tbody>'
      h << '</table>'
    end

    h.join("\n").html_safe
  end
end
