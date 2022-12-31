module Member::Addon
  module Bookmark
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      has_many :bookmarks, class_name: "Member::Bookmark", foreign_key: :member_id, dependent: :destroy
    end

    def bookmark_condition(content)
      { site_id: content.site_id, member_id: id, content_id: content.id, content_type: content.class.name }
    end

    def bookmark_registerd?(content)
      Member::Bookmark.and_public.where(bookmark_condition(content)).present?
    end

    def register_bookmark(content)
      item = Member::Bookmark.find_or_initialize_by(bookmark_condition(content))
      item.updated = Time.zone.now
      item.deleted = nil
      item.save
    end

    def cancel_bookmark(content)
      item = Member::Bookmark.where(bookmark_condition(content)).first
      item ? item.destroy : false
    end

    def squish_bookmarks
      bookmarks.each do |item|
        content = item.content
        next if content && content.public?
        item.set(deleted: Time.zone.now)
      end
    end
  end
end
