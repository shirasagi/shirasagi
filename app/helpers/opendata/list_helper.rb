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
        if cur_item.loop_setting.present?
          ih = item.render_template(cur_item.loop_setting.html, self)
        elsif cur_item.loop_html.present?
          ih = cur_item.render_loop_html(item)
        else
          ih = []
          ih << '<article class="item-#{class} #{new} #{current}">'
          ih << '  <header>'
          ih << '    <time datetime="#{date.iso}">#{date.long}</time>'
          ih << '    <h2>'
          ih << '      <a href="#{url}">#{name}</a>'
          if item.parent.becomes_with_route.show_point?
            ih << "      <span class=\"point\">\#{#{item.route.sub(/^.*\//, '')}_point}</span>"
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

  def render_user_agent(user_agent, accept_language:)
    return if user_agent.blank?

    browser = Browser.new(user_agent, accept_language: accept_language) rescue nil
    return user_agent if browser.blank?

    html = "<label class=\"browser-name\">#{browser.name}</label>"
    if browser.full_version.present? && browser.full_version != "0.0"
      html += " "
      html += "<label class=\"version\">#{browser.full_version}</label>"
    end
    if browser.platform.name != "Other"
      html += "@"
      html += "<label class=\"platform\">#{browser.platform.name}</label>"
    end

    html.html_safe
  end
end
