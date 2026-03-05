class Cms::NodesTreeComponent < ApplicationComponent
  include ActiveModel::Model
  include Cms::NodeHelper
  include SS::MaterialIconsHelper
  include SS::StimulusHelper
  include SS::ButtonToHelper
  include SS::CacheableComponent

  attr_accessor :site, :user

  self.cache_key = -> do
    [ site.id, *folders_signature ]
  end

  def root_nodes
    return @root_nodes if @root_nodes
    build_tree
  end

  private

  def all_folders
    @folders ||= begin
      criteria = Cms::Node.all
      criteria = criteria.site(site)
      criteria = criteria.order_by(filename: 1)
      criteria = criteria.only(:id, :site_id, :name, :filename, :depth, :route, :view_route, :updated, :group_ids)
      folders = criteria.to_a
      folders.each { _1.site = _1.cur_site = site }
      folders
    end
  end

  def readable_folders
    @readable_folders ||= all_folders.select { _1.allowed?(:read, user, site: site) }
  end

  def folders_signature
    [ readable_folders.length, readable_folders.map { _1.updated.to_i }.max || 0 ]
  end

  def build_tree
    @root_nodes = []

    filename_node_map = all_folders.index_by(&:filename)

    parent_map = {}
    readable_folders.to_a.each do |node|
      wrap = SS::TreeBaseComponent::NodeItem.new(
        id: node.id, name: node.name, depth: node.depth, updated: node.updated,
        url: item_url(node), opens: false, children: [])
      parent_map[node.filename] = wrap
      if node.depth == 1
        @root_nodes << wrap
        next
      end

      parent_filename = File.dirname(node.filename)
      parent_depth = node.depth - 1
      loop do
        parent_wrap = parent_map[parent_filename]
        if parent_wrap
          parent_wrap.children << wrap
          break
        end

        parent_node = filename_node_map[parent_filename]
        if parent_node
          url = parent_node.allowed?(:read, user, site: site) ? item_url(parent_node) : nil
          parent_wrap = SS::TreeBaseComponent::NodeItem.new(
            id: parent_node.id, name: parent_node.name, depth: parent_node.depth, updated: parent_node.updated,
            url: url, opens: false, children: [])
        else
          name = File.basename(parent_filename)
          parent_wrap = SS::TreeBaseComponent::NodeItem.new(
            id: :not_found, name: name, depth: parent_depth, updated: ::SS::EPOCH_TIME,
            url: nil, opens: false, children: [])
        end
        parent_wrap.children << wrap

        if parent_depth == 1
          @root_nodes << parent_wrap
          break
        end

        parent_filename = File.dirname(parent_filename)
        parent_depth -= 1
      end
    end

    @root_nodes
  end

  def item_url(item)
    item.respond_to?(:view_route) ? contents_path(item) : cms_node_nodes_path(cid: item)
  end
end
