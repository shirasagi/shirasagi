class Cms::PageSearchNaviComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user

  self.cache_key = -> do
    [ cur_site.id, items_fingerprint ]
  end

  def render?
    items.present?
  end

  private

  def items
    @items ||= begin
      criteria = Cms::PageSearch.all.site(@cur_site)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.reorder(order: 1)
      criteria.only(:_id, :name, :updated).to_a
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
