class Sys::User
  include SS::User::Model
  include Sys::Addon::Role
  include Sys::Permission

  set_permission_name "sys_users", :edit
end
