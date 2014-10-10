class Cms::Site
  include SS::Site::Model
  include Cms::Permission

  set_permission_name "cms_sites"
end
