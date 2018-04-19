class MailPage::Page
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Cms::Addon::EditLock
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Cms::Addon::Body
  include Cms::Addon::File
  include Map::Addon::Page
  include Cms::Addon::RelatedPage
  include MailPage::Addon::ArrivalPlan
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "article_pages"

  field :mail_page_original_mail, type: String

  default_scope ->{ where(route: "mail_page/page") }
end
