class Sys::Site
  include SS::Site::Model
  include Sys::Permission

  set_permission_name "sys_sites"
end
