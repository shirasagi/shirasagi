class Cms::Site
  include SS::Model::Site
  include Cms::SitePermission
  include Cms::Addon::PageSetting
  include Cms::Addon::DefaultReleasePlan
  include SS::Addon::MobileSetting
  include SS::Addon::MapSetting

  set_permission_name "cms_sites"
end
