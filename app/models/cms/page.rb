class Cms::Page
  extend ActiveSupport::Autoload
  include Model
  include Cms::Addon::Meta
  include Cms::Addon::Body
  include Cms::Addon::File
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::RelatedPage
  include Category::Addon::Category
  include Event::Addon::Date
  include Map::Addon::Page
  include Workflow::Addon::Approver
  include Contact::Addon::Page
  include History::Addon::Backup

  index({ site_id: 1, filename: 1 }, { unique: true })
end
