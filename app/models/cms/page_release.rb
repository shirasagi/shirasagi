class Cms::PageRelease
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site

  index({ created: 1 }, { expire_after_seconds: 1.month })
  index({ site_id: 1, filename: 1 })

  field :filename, type: String
  field :action, type: String, default: "release"

  belongs_to :page, class_name: "Cms::Page"

  validates :filename, presence: true
  validates :action, presence: true
  validates :page_id, presence: true

  def set_page(page)
    self.cur_user = page.user
    self.cur_site = page.site
    self.filename = page.filename
    self.page_id = page.id
    self
  end

  class << self
    def release(page, filename = nil)
      filename ||= page.filename
      item = self.new.set_page(page)
      item.attributes = { filename: filename, action: 'release' }
      item.save

      Cms::PageIndexQueue.new(item.attributes).save if page.site.elasticsearch_enabled?
    end

    def close(page, filename = nil)
      filename ||= page.filename
      item = self.new.set_page(page)
      item.attributes = { filename: filename, action: 'close' }
      item.save

      Cms::PageIndexQueue.new(item.attributes).save if page.site.elasticsearch_enabled?
    end
  end
end
