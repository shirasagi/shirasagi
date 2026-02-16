class Cms::ShortCutNaviComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user, :cur_node

  self.cache_key = -> do
    [ cur_site.id, items_fingerprint ]
  end

  def render?
    items.present?
  end

  private

  def contents_path(node)
    route = node.view_route.presence || node.route
    "/.s#{cur_site.id}/" + route.pluralize.sub("/", "#{node.id}/")
  rescue StandardError => e
    raise(e) unless Rails.env.production?
    node_nodes_path(site: cur_site, cid: node)
  end

  def items
    @items ||= begin
      criteria = Cms::Node.all.site(@cur_site)
      criteria = criteria.where(shortcuts: Cms::Node::SHORTCUT_NAVI)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.reorder(name: 1, id: 1)
      criteria.only(:_id, :name, :route, :view_route, :updated).to_a
    end
  end

  def items_fingerprint
    @items_fingerprint ||= begin
      crc32 = 0
      items.each do |item|
        crc32 = Zlib.crc32(item.id.to_s(36), crc32)
        crc32 = Zlib.crc32(item.updated.to_i.to_s(36), crc32)
      end
      crc32
    end
  end
end
