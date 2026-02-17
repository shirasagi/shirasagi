class Cms::ShortcutComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent
  include Cms::NodeHelper
  include SS::DateTimeHelper

  cattr_accessor :max_items_per_page, instance_accessor: false
  self.max_items_per_page = 100

  attr_accessor :cur_site, :cur_user, :page, :s

  self.cache_key = -> do
    [ cur_site.id, items_fingerprint ]
  end

  SearchParams = Data.define(:mod, :keyword) do
    def initialize(mod: nil, keyword: nil)
      super
    end

    def empty?
      (mod.nil? || mod.empty?) && (keyword.nil? || keyword.empty?)
    end
  end

  def render?
    raw_items.present? || s.present?
  end

  def cache_component(&block)
    if use_cache?
      # enable cache if it is configured
      return super
    end

    # no cache
    capture(&block)
  end

  # override Cms::NodeHelper#contents_path to reduce database accesses
  def contents_path(node)
    route = node.view_route.presence || node.route
    "/.s#{cur_site.id}/" + route.pluralize.sub("/", "#{node.id}/")
  rescue StandardError => e
    raise(e) unless Rails.env.production?
    node_nodes_path(site: cur_site, cid: node)
  end

  # override Cms::NodeHelper#cms_preview_links
  def cms_preview_links(item)
    path = cms_preview_path(site: cur_site, path: item.preview_path)
    h = []
    h << link_to(t("ss.links.pc_preview"), path, target: "_blank", rel: "noopener")
    h << link_to(t("ss.links.sp_preview"), path, class: 'cms-preview-sp', target: "_blank", rel: "noopener")

    if cur_site.mobile_enabled?
      path = cms_preview_path(site: cur_site, path: item.mobile_preview_path)
      h << link_to(t("ss.links.mobile_preview"), path, class: 'cms-preview-mb', target: "_blank", rel: "noopener")
    end

    h
  end

  private

  def use_cache?
    return false if s.present?
    return false if page.numeric? && page.to_i > 1
    true
  end

  def criteria
    @criteria ||= begin
      criteria = Cms::Node.all.site(cur_site)
      criteria = criteria.allow(:read, cur_user, site: cur_site)
      if s.try(:mod).present?
        criteria = criteria.where(route: /^#{::Regexp.escape(s.mod)}\//)
      end
      if s.try(:keyword).present?
        criteria = criteria.search(keyword: s.keyword)
      end
      criteria = criteria.where(shortcuts: Cms::Node::SHORTCUT_SYSTEM)
      criteria = criteria.reorder(filename: 1)
      criteria = criteria.page(page).per(self.class.max_items_per_page)
      criteria
    end
  end

  def raw_items
    @raw_items ||= begin
      items = criteria.to_a
      items.each { _1.site = _1.cur_site = cur_site }
      items
    end
  end

  def items
    @items ||= begin
      items = raw_items.dup
      if criteria.total_pages > 1
        limit = criteria.limit_value
        offset = criteria.offset_value
        total_count = criteria.total_count
        items = Kaminari.paginate_array(items, limit: limit, offset: offset, total_count: total_count)
      end
      items
    end
  end

  def items_fingerprint
    @items_fingerprint ||= begin
      crc32 = 0
      raw_items.each do |item|
        crc32 = Zlib.crc32(item.id.to_s(36), crc32)
        crc32 = Zlib.crc32(item.updated.to_i.to_s(36), crc32)
      end
      crc32
    end
  end
end
