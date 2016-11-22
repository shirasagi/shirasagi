class Event::Page
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Gravatar::Addon::Gravatar
  include Cms::Addon::Body
  include Cms::Addon::File
  include Category::Addon::Category
  include Cms::Addon::ParentCrumb
  include Event::Addon::Body
  include Cms::Addon::AdditionalInfo
  include Event::Addon::Date
  include Map::Addon::Page
  include Cms::Addon::RelatedPage
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup
  include Event::Addon::Csv::Page

  set_permission_name "event_pages"

  default_scope ->{ where(route: "event/page") }
end
