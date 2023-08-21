class Sys::PostalCode
  include SS::Model::PostalCode
  include Sys::Permission

  set_permission_name "sys_settings", :edit
end
