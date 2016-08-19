class Cms::Site
  include SS::Model::Site
  include Cms::SitePermission
  include Cms::Addon::PageSetting
  include Cms::Addon::DefaultReleasePlan
  include SS::Addon::MobileSetting
  include SS::Addon::MapSetting
  include SS::Addon::KanaSetting
  include SS::Addon::FacebookSetting
  include SS::Addon::TwitterSetting
  include Opendata::Addon::SiteSetting

  set_permission_name "cms_sites", :edit
end
