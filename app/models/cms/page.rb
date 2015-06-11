class Cms::Page
  include Cms::Model::Page
  include Cms::Addon::Meta
  include Cms::Addon::Body
  include Cms::Addon::File
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::RelatedPage
  include Cms::Addon::ParentCrumb
  include Category::Addon::Category
  include Event::Addon::Date
  include Map::Addon::Page
  include ::Workflow::Addon::Approver
  include Contact::Addon::Page
  include History::Addon::Backup
  include Workflow::Addon::Branch

  index({ site_id: 1, filename: 1 }, { unique: true })
end
