class Workflow::Route
  include Workflow::Model::Route
  include Cms::SitePermission

  set_permission_name "cms_users", :edit

  scope :site, ->(site) { self.in(group_ids: Cms::Group.site(site).pluck(:id)) }
end
