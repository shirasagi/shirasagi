class Ldap::SyncTask
  include SS::Model::Task
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_users", :edit

  default_scope ->{ where(name: "ldap::sync") }

  field :results, type: Hash
end
