module Cms::ChildList
  extend ActiveSupport::Concern
  include SS::TemplateVariable

  included do
    template_variable_handler :category_nodes, :template_variable_handler_name
    template_variable_handler :category_pages, :template_variable_handler_name
    template_variable_handler :child_nodes, :template_variable_handler_name
    template_variable_handler :child_pages, :template_variable_handler_name
    template_variable_handler :child_items, :template_variable_handler_name
  end

  def child_limit
    value = parent ? parent[:child_limit].to_i : self[:child_limit].to_i
    (value < 1 || 1000 < value) ? 5 : value
  end

  def category_nodes
    @items = Cms::Node.site(site).and_public.
      where({ filename: /^#{self.filename}\//, route: /^category\// }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_limit)
    render_child_items
  end

  def category_pages
    @items = Cms::Page.site(site).and_public.
      in({ category_ids: self.id }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_limit)
    render_child_items
  end

  def child_pages
    @items = Cms::Page.site(site).and_public.
      where({ filename: /^#{self.filename}\// }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_limit)
    render_child_items
  end

  def child_nodes
    @items = Cms::Node.site(site).and_public.
      where({ filename: /^#{self.filename}\// }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_limit)
    render_child_items
  end

  def child_items
    return category_nodes if self.route == 'category/node' && category_nodes.present?
    return category_pages if self.route == 'category/page' && category_pages.present?
    return child_pages if child_pages.present?
    child_nodes if child_nodes.present?
  end

  def render_child_items
    parent_node = parent.becomes_with_route
    html = ''
    html << parent_node.child_upper_html if parent_node.child_upper_html.present?
    if parent_node.child_loop_html.present?
      @items.each do |item|
        html << parent_node.render_child_loop_html(item)
      end
    end
    html << parent_node.child_lower_html if parent_node.child_lower_html.present?
    html.html_safe
  end

  def render_child_loop_html(item, opts = {})
    item = item.becomes_with_route rescue item
    item.render_template(opts[:html] || child_loop_html, self)
  end
end
