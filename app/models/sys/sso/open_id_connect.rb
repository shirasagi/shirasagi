class Sys::SSO::OpenIDConnect
  include Sys::Model::SSO
  include Sys::Permission

  set_permission_name "sys_users", :edit
end
