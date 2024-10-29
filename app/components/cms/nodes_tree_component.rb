class Cms::NodesTreeComponent < ApplicationComponent
  include ActiveModel::Model
  include Cms::NodeHelper
  include SS::CacheableComponent

  attr_accessor :site, :user

  self.cache_key = ->{ [ site.id, folders.map(&:id), folders.max(&:updated).to_i ] }

  class NodeItem
    include ActiveModel::Model

    attr_accessor :item, :url, :children

    delegate :id, :name, :filename, :depth, :route, :view_route, :updated, to: :item

    def children?
      children.present?
    end
  end

  def root_items
    @root_items ||= begin
      items = folders.select { |node| node.depth == 1 }
      items.map { |node| NodeItem.new(item: node, url: item_url(node), children: child_items(node)) }
    end
  end

  private

  def folders
    @folders ||= begin
      criteria = Cms::Node.all
      criteria = criteria.site(site)
      criteria = criteria.allow(:read, user, site: site)
      criteria = criteria.order_by(filename: 1)
      criteria = criteria.only(:id, :site_id, :name, :filename, :depth, :route, :view_route, :updated)
      nodes = criteria.to_a
      nodes.each { |node| node.site = node.cur_site = site }
      nodes
    end
  end

  def child_items(item)
    prefix_filename = "#{item.filename}/"
    folders
      .select { |node| node.filename.start_with?(prefix_filename) && node.depth == item.depth + 1 }
      .map { |node| NodeItem.new(item: node, url: item_url(node), children: child_items(node)) }
  end

  def item_url(item)
    item.respond_to?(:view_route) ? contents_path(item) : cms_node_nodes_path(cid: item)
  end
end
