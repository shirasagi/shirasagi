class Sitemap::Page
  include Cms::Model::Page
  include Workflow::Addon::Branch
  include Workflow::Addon::Approver
  include Cms::Addon::Meta
  include Sitemap::Addon::Body
  include Contact::Addon::Page
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "sitemap_pages"

  default_scope ->{ where(route: "sitemap/page") }
end
