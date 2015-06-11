class Cms::Site
  include SS::Model::Site
  include Cms::SitePermission

  set_permission_name "cms_sites"
end
