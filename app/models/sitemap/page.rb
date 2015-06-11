class Sitemap::Page
  include Cms::Model::Page
  include Cms::Addon::Meta
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Sitemap::Addon::Body
  include Workflow::Addon::Approver
  include Contact::Addon::Page
  include History::Addon::Backup
  include Workflow::Addon::Branch

  set_permission_name "sitemap_pages"

  default_scope ->{ where(route: "sitemap/page") }
end
