module Category::TemplateVariable
  extend ActiveSupport::Concern
  include SS::TemplateVariable

  included do
    template_variable_handler :category_nodes, :template_variable_handler_name
    template_variable_handler :category_pages, :template_variable_handler_name
    template_variable_handler :category_items, :template_variable_handler_name
  end

  def category_limit
    value = self[:category_limit].to_i
    (value < 1 || 1000 < value) ? 5 : value
  end

  def category_nodes
    @items = Cms::Node.
      where({ filename: /^#{self.filename}\//, route: /^category\// }).
      order_by(self.sort_hash).
      limit(category_limit)
    render_category_items
  end

  def category_pages
    @items = Cms::Page.
      in({ category_ids: self.id }).
      order_by(self.sort_hash).
      limit(category_limit)
    render_category_items
  end

  def category_items
    return category_nodes if self.route == 'category/node' && category_nodes.present?
    category_pages if self.route == 'category/page' && category_pages.present?
  end

  def render_category_items
    parent_category = parent.becomes_with_route
    return '' if parent_category.route != 'category/node'
    html = ''
    html << parent_category.category_upper_html if parent_category.category_upper_html.present?
    if parent_category.category_loop_html.present?
      @items.each do |item|
        html << parent_category.render_category_loop_html(item)
      end
    end
    html << parent_category.category_lower_html if parent_category.category_lower_html.present?
    html.html_safe
  end

  def render_category_loop_html(item, opts = {})
    item = item.becomes_with_route rescue item
    item.render_template(opts[:html] || category_loop_html, self)
  end
end
