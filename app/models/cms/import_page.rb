class Cms::ImportPage
  include Cms::Model::Page
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Import::Body
  include Cms::Addon::Release
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  index({ site_id: 1, filename: 1 }, { unique: true })

  default_scope ->{ where(route: "cms/import_page") }
end
