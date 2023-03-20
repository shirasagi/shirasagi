class Article::Page
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Cms::Addon::EditLock
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Cms::Addon::TwitterPoster
  include Cms::Addon::LinePoster
  include Gravatar::Addon::Gravatar
  include Cms::Addon::Thumb
  include Cms::Addon::RedirectLink
  include Cms::Addon::Body
  include Cms::Addon::BodyPart
  include Cms::Addon::File
  include Cms::Addon::Form::Page
  include Category::Addon::Category
  include Cms::Addon::ParentCrumb
  include Event::Addon::Date
  include Map::Addon::Page
  include Cms::Addon::RelatedPage
  include Contact::Addon::Page
  include Cms::Addon::Tag
  include Cms::Addon::OpendataRef::Dataset
  include Cms::Addon::OpendataRef::Category
  include Cms::Addon::OpendataRef::Area
  include Cms::Addon::OpendataRef::DatasetGroup
  include Cms::Addon::OpendataRef::License
  include Cms::Addon::OpendataRef::Resource
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup
  include Cms::Addon::ForMemberPage
  include Cms::Lgwan::Page

  after_save :new_size_input, if: ->{ @db_changes }

  set_permission_name "article_pages"

  default_scope ->{ where(route: "article/page") }
end
