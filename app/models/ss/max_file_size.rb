class SS::MaxFileSize
  include SS::Model::MaxFileSize
  include Sys::Permission

  set_permission_name "sys_users", :edit
end
