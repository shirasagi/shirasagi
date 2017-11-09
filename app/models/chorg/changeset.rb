class Chorg::Changeset
  include Chorg::Model::Changeset
  include Cms::SitePermission

  set_permission_name 'chorg_revisions', :edit
end
