class Sys::Group
  include SS::Model::Group
  include Sys::Permission
  include Contact::Addon::Group

  set_permission_name "sys_users", :edit
end
