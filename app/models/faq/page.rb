class Faq::Page
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Cms::Addon::EditLock
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Cms::Addon::EditorSetting
  include Cms::Addon::TwitterPoster
  include Cms::Addon::LinePoster
  include Gravatar::Addon::Gravatar
  include Faq::Addon::Question
  include Cms::Addon::Body
  include Cms::Addon::File
  include Category::Addon::Category
  include Cms::Addon::ParentCrumb
  include Event::Addon::Date
  include Cms::Addon::Tag
  include Cms::Addon::RelatedPage
  include Contact::Addon::Page
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "faq_pages"

  after_save :new_size_input, if: ->{ @db_changes }

  default_scope ->{ where(route: "faq/page") }
end
