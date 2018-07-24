class Event::Ical
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Event::Addon::IcalBody
  include Category::Addon::Category
  include Cms::Addon::ParentCrumb
  include Event::Addon::Body
  include Cms::Addon::AdditionalInfo
  include Event::Addon::Date
  include Map::Addon::Page
  include Cms::Addon::Tag
  include Cms::Addon::RelatedPage
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "event_pages"

  default_scope ->{ where(route: "event/ical") }
end
