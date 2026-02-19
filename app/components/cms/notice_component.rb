class Cms::NoticeComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent
  include SS::DateTimeHelper

  attr_accessor :cur_site, :cur_user

  LIMIT_SIZE = 5

  self.cache_key = -> do
    [ cur_site.id, fingerprint ]
  end

  def render?
    cms_notices.present?
  end

  private

  def all_cms_notices
    @all_cms_notices ||= begin
      criteria = Cms::Notice.all
      criteria = criteria.site(cur_site)
      criteria = criteria.and_public
      criteria = criteria.target_to(cur_user)
      criteria = criteria.reorder(notice_severity: 1, released: -1)
      criteria = criteria.only(:_id, :name, :notice_severity, :released, :updated)
      # 1つ余分に取得する；1つ余分に存在するかどうかで「もっと見る」を表示するかどうかを決める
      criteria.limit(LIMIT_SIZE + 1).to_a
    end
  end

  def cms_notices
    all_cms_notices.take(LIMIT_SIZE)
  end

  def fingerprint
    @fingerprint ||= begin
      crc32 = 0
      all_cms_notices.each do |item|
        crc32 = Zlib.crc32(item.id.to_s(36), crc32)
        crc32 = Zlib.crc32(item.updated.to_i.to_s(36), crc32)
      end
      crc32
    end
  end

  def next_page?
    all_cms_notices[LIMIT_SIZE]
  end
end
