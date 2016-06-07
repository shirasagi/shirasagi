class Cms::PostalCode
  include SS::Model::PostalCode
  include Cms::SitePermission

  set_permission_name "cms_tools", :use
end
