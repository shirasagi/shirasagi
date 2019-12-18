module Cms::ChildList
  extend ActiveSupport::Concern
  include SS::TemplateVariable

  included do
    template_variable_handler :category_nodes, :template_variable_handler_child_items
    template_variable_handler :category_pages, :template_variable_handler_child_items
    template_variable_handler :child_nodes, :template_variable_handler_child_items
    template_variable_handler :child_pages, :template_variable_handler_child_items
    template_variable_handler :child_items, :template_variable_handler_child_items
  end

  def child_list_limit
    parent ? parent[:child_limit].to_i : self[:child_limit].to_i
  end

  def category_nodes
    Cms::Node.site(site).and_public.
      where({ filename: /^#{self.filename}\//, route: /^category\// }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_list_limit)
  end

  def category_pages
    Cms::Page.site(site).and_public.
      in({ category_ids: self.id }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_list_limit)
  end

  def child_pages
    Cms::Page.site(site).and_public.
      where({ filename: /^#{self.filename}\// }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_list_limit)
  end

  def child_nodes
    Cms::Node.site(site).and_public.
      where({ filename: /^#{self.filename}\// }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_list_limit)
  end

  def child_items
    return category_nodes if self.route == 'category/node'
    return category_pages if self.route == 'category/page'

    items = child_nodes + child_pages
    items.sort! do |a, b|
      cmp = 0
      self.sort_hash.each do |k, v|
        cmp = (a.send(k) <=> b.send(k)) * v
        break if cmp.nonzero?
      end
      next cmp if cmp.nonzero?

      cmp = a.id <=> b.id
      next cmp if cmp.nonzero?

      a.collection_name <=> b.collection_name
    end
    items.take(child_list_limit)
  end

  def template_variable_handler_child_items(name, issuer)
    items = self.send(name)
    parent_node = parent.becomes_with_route
    html = ''
    html << parent_node.child_upper_html.to_s
    if parent_node.child_loop_html.present?
      items.each do |item|
        html << parent_node.render_child_loop_html(item)
      end
    end
    html << parent_node.child_lower_html.to_s
    html.html_safe
  end

  def render_child_loop_html(item, opts = {})
    item = item.becomes_with_route rescue item
    item.render_template(opts[:html] || child_loop_html, self)
  end
end
