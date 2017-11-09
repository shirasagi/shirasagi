class Gws::Chorg::Changeset
  include Chorg::Model::Changeset
  include Gws::SitePermission

  set_permission_name 'gws_chorg_revisions', :edit
end
