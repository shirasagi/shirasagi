class Cms::PageRelease
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site

  index({ created: 1 }, { expire_after_seconds: 3.months })
  index({ site_id: 1, filename: 1 })

  field :state, type: String, default: "active"
  field :es_state, type: String
  field :filename, type: String
  field :action, type: String, default: "release"

  belongs_to :page, class_name: "Cms::Page"

  validates :state, presence: true
  validates :filename, presence: true
  validates :action, presence: true
  validates :page_id, presence: true

  scope :active, ->{ where(state: 'active') }
  scope :unindexed, -> { where(es_state: nil) }

  def set_page(page)
    self.cur_user = page.user
    self.cur_site = page.site
    self.filename = page.filename
    self.page_id = page.id
    self
  end

  class << self
    def same_pages(page)
      self.site(page.site).where(filename: page.filename)
    end

    def release(page, filename = nil)
      filename ||= page.filename
      same_pages(page).where(filename: filename).active.update_all({ state: 'inactive' })

      item = self.new.set_page(page)
      item.attributes = { filename: filename, action: 'release' }
      item.save
    end

    def close(page, filename = nil)
      filename ||= page.filename
      same_pages(page).where(filename: filename).active.update_all({ state: 'inactive' })

      item = self.new.set_page(page)
      item.attributes = { filename: filename, action: 'close' }
      item.save
    end
  end
end
