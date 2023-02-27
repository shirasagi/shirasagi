module Cms::ChildList
  extend ActiveSupport::Concern
  include SS::TemplateVariable

  included do
    attr_accessor :child_list_limit

    template_variable_handler :category_nodes, :template_variable_handler_child_items
    template_variable_handler :category_pages, :template_variable_handler_child_items
    template_variable_handler :child_nodes, :template_variable_handler_child_items
    template_variable_handler :child_pages, :template_variable_handler_child_items
    template_variable_handler :child_items, :template_variable_handler_child_items
  end

  def category_nodes
    @_child_list_category_nodes ||= begin
      items = Category::Node::Base.site(site).and_public
      items = items.where(filename: /^#{::Regexp.escape(self.filename)}\//)
      items = items.where(self.condition_hash)
      items = items.order_by(self.sort_hash)
      items = items.limit(child_list_limit)
      items.to_a
    end
  end

  def category_pages
    @_child_list_category_pages ||= begin
      items = Cms::Page.public_list(site: site, node: self)
      items = items.order_by(self.sort_hash)
      items = items.limit(child_list_limit)
      items.to_a
    end
  end

  def child_pages
    @_child_list_pages ||= begin
      items = Cms::Page.public_list(site: site, node: self)
      items = items.order_by(self.sort_hash)
      items = items.limit(child_list_limit)
      items.to_a
    end
  end

  def child_nodes
    @_child_list_nodes ||= begin
      items = Cms::Node.site(site).and_public
      items = items.where(filename: /^#{::Regexp.escape(self.filename)}\//)
      items = items.where(self.condition_hash)
      items = items.order_by(self.sort_hash)
      items = items.limit(child_list_limit)
      items.to_a
    end
  end

  def child_items
    return category_nodes if self.route == 'category/node'
    return category_pages if self.route == 'category/page'
    return child_nodes if child_pages.blank?
    return child_pages if child_nodes.blank?

    items = []
    nodes = child_nodes
    pages = child_pages
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
    self.child_list_limit = issuer.child_limit.to_i
    items = self.child_items

    issuer.instance_exec(items) do |items|
      html = []
      html << child_upper_html.to_s
      if child_loop_html.present?
        items.each do |item|
          html << item.render_template(child_loop_html, self)
        end
      end
      html << child_lower_html.to_s
      html.join("\n").html_safe
    end
  end
end
