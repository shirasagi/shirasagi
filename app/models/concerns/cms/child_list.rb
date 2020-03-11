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
      where({ filename: /^#{::Regexp.escape(self.filename)}\//, route: /^category\// }).
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
      where({ filename: /^#{::Regexp.escape(self.filename)}\// }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_list_limit)
  end

  def child_nodes
    Cms::Node.site(site).and_public.
      where({ filename: /^#{::Regexp.escape(self.filename)}\// }).
      where(self.condition_hash).
      order_by(self.sort_hash).
      limit(child_list_limit)
  end

  def child_items
    return category_nodes if self.route == 'category/node'
    return category_pages if self.route == 'category/page'
    return child_nodes if child_pages.blank?
    return child_pages if child_nodes.blank?

    items = []
    nodes = child_nodes.to_a
    pages = child_pages.to_a
    child_list_limit.times do
      cmp = 0
      self.sort_hash.each do |k, v|
        cmp = (nodes.first.send(k) <=> pages.first.send(k)) * v
        break if cmp.nonzero?
      end
      cmp = nodes.first.id <=> pages.first.id if cmp.zero?
      cmp = nodes.first.collection_name <=> pages.first.collection_name if cmp.zero?
      if cmp.negative?
        items << nodes.shift
        if nodes.blank?
          items << pages
          break
        end
      else
        items << pages.shift
        if pages.blank?
          items << nodes
          break
        end
      end
    end
    items.flatten.take(child_list_limit)
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
