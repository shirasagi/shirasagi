class Cms::SnsPostLog::Base
  extend SS::Translation
  include SS::Document
  include Cms::Reference::Site

  field :action, type: String, default: "unknown"
  field :state, type: String, default: "error"
  field :error_message, type: String

  belongs_to :page, class_name: "Cms::Page"
  validates :page_id, presence: true

  class << self
    def create_with(page)
      log = self.new
      log.site = page.site
      log.page = page
      yield(log)
      log.save
    end
  end
end
