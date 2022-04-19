class Sys::Site
  include SS::Model::Site
  include SS::Addon::PartnerSetting
  include Sys::Permission
  include SS::Addon::MaintMode

  set_permission_name "sys_sites", :edit
end
