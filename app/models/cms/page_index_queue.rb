class Cms::PageIndexQueue
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site

  index({ created: 1 }, { expire_after_seconds: 1.week })
  index({ site_id: 1, filename: 1 })

  field :filename, type: String
  field :action, type: String, default: "release"

  belongs_to :page, class_name: "Cms::Page"

  validates :filename, presence: true
  validates :action, presence: true
  validates :page_id, presence: true

  def old_queues
    self.class.where(site_id: site_id, filename: filename).ne(id: id)
  end

  def job_action
    return 'delete' if action == 'close'
    'index'
  end
end
