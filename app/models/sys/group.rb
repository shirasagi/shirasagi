class Sys::Group
  include SS::Group::Model
  include Sys::Permission
  include Contact::Addon::Group

  set_permission_name "sys_users", :edit
end
