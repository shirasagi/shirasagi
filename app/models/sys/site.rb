class Sys::Site
  include SS::Model::Site
  include SS::Addon::PartnerSetting
  include Sys::Permission
  include SS::Addon::MaintenanceMode
  include Chorg::SiteSetting

  set_permission_name "sys_sites", :edit
end
