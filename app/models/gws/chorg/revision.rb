class Gws::Chorg::Revision
  include Chorg::Model::Revision
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'gws_chorg_revisions', :edit
end
