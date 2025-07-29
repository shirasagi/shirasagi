module Lsorg::ListHelper
  include Cms::ListHelper

  def default_loop_liquid
    ih = []
    ih << '{% for dept in root.children %}'
    ih << '<h2 class="{{ dept.basename }}">{{ dept.name }}</h2>'
    ih << '<table class="{{ dept.basename }} children">'
    ih << '  <thead>'
    ih << '     <tr>'
    ih << '       <th>' + I18n.t("lsorg.views.group") + '</th>'
    ih << '       <th>' + I18n.t("lsorg.views.overview") + '</th>'
    ih << '       <th>' + I18n.t("lsorg.views.tel") + '</th>'
    ih << '       <th>' + I18n.t("lsorg.views.contact") + '</th>'
    ih << '     </tr>'
    ih << '  </thead>'
    ih << '  <tbody>'
    ih << '    {% for div in dept.children %}'
    ih << '      <tr class="{{ div.basename }}">'
    ih << '        {% if div.node %}'
    ih << '          <td><a href="{{ div.node.url }}">{{ div.name }}</a></td>'
    ih << '        {% else %}'
    ih << '          <td>{{ div.name }}</td>'
    ih << '        {% endif %}'
    ih << '        <td>{{ div.overview }}</td>'
    ih << '        <td>{{ div.main_contact.contact_tel }}</td>'
    ih << '        {% if inquiry_form %}'
    ih << '          <td><a href="{{ inquiry_form.url }}?group={{ div.group.id }}">' + I18n.t("lsorg.views.contact") + '</a></td>'
    ih << '        {% else %}'
    ih << '          <td></td>'
    ih << '        {% endif %}'
    ih << '      </tr>'
    ih << '    {% endfor %}'
    ih << '  </tbody>'
    ih << '</table>'
    ih << '{% endfor %}'
    ih.join("\n").freeze
  end

  def render_group_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    source = cur_item.loop_liquid.presence || default_loop_liquid
    assigns = { "roots" => @items.to_a, "root" => @items.first, "inquiry_form" => @cur_site.inquiry_form }
    render_list_with_liquid(source, assigns)
  end
end
