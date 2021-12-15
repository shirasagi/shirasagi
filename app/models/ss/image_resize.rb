class SS::ImageResize
  include SS::Model::ImageResize
  include Sys::Permission

  set_permission_name "sys_users", :edit
end
