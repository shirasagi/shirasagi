class Cms::NodesTreeComponent < ApplicationComponent
  include ActiveModel::Model
  include Cms::NodeHelper
  include SS::MaterialIconsHelper
  include SS::StimulusHelper
  include SS::CacheableComponent

  attr_accessor :site, :user

  self.cache_key = ->{ [ site.id, root_items.map(&:id), folders.count, folders.max(&:updated).to_i ] }

  class NodeItem
    include ActiveModel::Model

    attr_accessor :item, :url, :children

    delegate :id, :name, :filename, :depth, :route, :view_route, :updated, to: :item

    def children?
      children.present?
    end
  end

  def root_items
    return @root_items if @root_items
    build_tree
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

  def build_tree
    @root_items = []
    parent_map = {}

    folders.each do |node|
      wrap = NodeItem.new(item: node, url: item_url(node), children: [])
      parent_map[node.filename] = wrap
      if node.depth == 1
        @root_items << wrap
        next
      end

      parent_filename = ::File.dirname(node.filename)
      parent_wrap = parent_map[parent_filename]
      unless parent_wrap
        Rails.logger.warn { "'#{node.filename}' hasn't parent node" }
        next
      end

      parent_wrap.children << wrap
    end

    @root_items
  end

  def item_url(item)
    item.respond_to?(:view_route) ? contents_path(item) : cms_node_nodes_path(cid: item)
  end
end
