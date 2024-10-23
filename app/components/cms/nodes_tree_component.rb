class Cms::NodesTreeComponent < ApplicationComponent
  include Cms::NodeHelper
  include SS::CacheableComponent

  self.cache_key = ->{ [ @site.id, @user.id ] }

  def initialize(site:, user:, item: nil, only_children: false, root_items: nil, type: nil)
    @type = type.presence || 'cms_nodes'
    @site = site
    @user = user
    @item = item
    @only_children = only_children
    @root_items = root_items
    @folders = []
  end

  # Move logic dependent on URL helpers to `before_render`
  def before_render
    @folders = fetch_folders
  end

  private

  def fetch_folders
    items = if @only_children && @item
              child_items
            else
              root_items
            end
    items_hash(items)
  end

  def root_items
    if @root_items.present?
      Cms::Node.in(id: @root_items).site(@site).
        allow(:read, @user, site: @site)
    else
      Cms::Node.site(@site).where(depth: 1).
        allow(:read, @user, site: @site)
    end
  end

  def child_items
    @item.present? ? @item.children.allow(:read, @user, site: @site) : []
  end

  def items_hash(items)
    items.map { |item| build_item_hash(item) }.compact.uniq.sort_by { |item| item[:filename].tr('/', "\0") }
  end

  def build_item_hash(item)
    return unless item.allowed?(:read, @user, site: @site)

    item_hash = {
      id: item.id,
      name: item.name,
      filename: item.filename,
      depth: item.depth,
      url: item_url(item), # This now works because view context is available
      is_current: @item.present? && item.id == @item.id,
      is_parent: @item.present? && @item.filename.start_with?("#{item.filename}/"),
      has_children: item.children.present?
    }

    if item.children.present?
      item_hash[:children] = item.children.allow(:read, @user, site: @site).map { |child| build_item_hash(child) }
    end

    item_hash
  end

  def item_url(item)
    return node_pages_path(cid: item.id) if @type == 'cms/page'
    return node_parts_path(cid: item.id) if @type == 'cms/part'
    return node_layouts_path(cid: item.id) if @type == 'cms/layout' 
    item.respond_to?(:view_route) ? contents_path(item) : cms_node_nodes_path(cid: item.id)
  end
end
