class Chorg::Revision
  include Chorg::Model::Revision
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name 'chorg_revisions', :edit
end
