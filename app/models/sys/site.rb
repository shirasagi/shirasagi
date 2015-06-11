class Sys::Site
  include SS::Model::Site
  include Sys::Permission

  set_permission_name "sys_sites"
end
