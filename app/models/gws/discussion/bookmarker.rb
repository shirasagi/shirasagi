class Gws::Discussion::Bookmarker
  include ActiveModel::Model

  attr_reader :site, :user, :forum, :bookmarks

  def initialize(site, user, forum)
    @site = site
    @user = user
    @forum = forum
    set_bookmarks
  end

  def set_bookmarks
    @bookmarks = begin
      items = []
      items = Gws::Discussion::Bookmark.site(site).user(user).
        where(forum_id: forum.id, :deleted.exists => false).to_a
      items = items.select do |item|
        next true if item.post
        item.set(deleted: Time.zone.now)
        false
      end
      items.index_by(&:post_id)
    end
  end

  def active?(post)
    bookmarks[post.id]
  end

  def inactive?(post)
    !bookmark_on?(post)
  end

  def toggle(post)
    active?(post) ? cancel(post) : register(post)
  end

  def register(post)
    item = Gws::Discussion::Bookmark.new
    item.cur_site = site
    item.cur_user = user
    item.forum = forum
    item.post = post
    item.updated = Time.zone.now
    item.deleted = nil
    item.save
    item
  end

  def cancel(post)
    item = bookmarks[post.id]
    item.destroy if item
    nil
  end
end
