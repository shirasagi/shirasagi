module Article::Addon
  module FormTable
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      belongs_to :form, class_name: "Cms::Form"
      belongs_to :node, class_name: "Article::Node::Page"
      permit_params :form_id, :node_id

      validates :form_id, presence: true

      # addon: cms/page_list
      self.use_conditions = false
      self.use_loop_settings = false
    end

    def form_options
      Cms::Form.where(site_id: @cur_site.id, sub_type: 'static').map { |item| [item.name, item.id] }
    end

    def node_options
      Article::Node::Page.where(site_id: @cur_site.id).map { |item| [item.name, item.id] }
    end

    def pages
      pages = Article::Page.where(form_id: form_id)
      pages = pages.node(node) if node_id
      pages
    end

    def condition_hash
      {}
    end

    def build_form_table_html
      return nil unless form
      return nil unless form.column_names

      h = []
      h << %(<table>)
      h << %(  <caption>#{name}</caption>)
      h << %(  <thead>)
      h << %(    <tr>)
      h << %(      <th scope="row">#{Article::Page.t(:name)}</th>)

      form.column_names.each { |name| h << %(      <th scope="row">#{name}</th>) }

      h << %(    </tr>)
      h << %(  </thead>)
      h << %(  <tbody>)
      h << %(    {% for page in pages %})
      h << %(    <tr>)
      h << %(      <td><a href="{{ page.url }}">{{ page.name }}</a></td>)

      form.column_names.each { |name| h << %(      <td>{{ page.values["#{name}"] }}</td>) }

      h << %(    </tr>)
      h << %(    {% endfor %})
      h << %(  </tbody>)
      h << %(</table>)
      h.join("\n")
    end

    def form_example_layout_html
      if html = build_form_table_html
        return html
      end

      <<~HTML
        <table>
          <thead>
            <tr>
              <th scope="row">#{Article::Page.t(:name)}</th>
              <th scope="row">項目名</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><a href="{{ page.url }}">{{ page.name }}</a></td>
              <td>{{ page.values["項目名1"] }}</td>
            </tr>
          </tbody>
        </table>
      HTML
    end

    def render_form_table(pages, registers)
      pages = pages.map { |page| page.to_liquid }
      layout = html.presence || build_form_table_html
      template = ::Cms.parse_liquid(layout, registers)
      template.render({ 'pages' => pages }).html_safe
    end

    def to_csv(items)
      Cms::FormDb.export_csv(form, items)
    end
  end
end
