class SS::User
  include SS::Model::User
  include SS::Reference::UserTitles
  include Sys::Addon::Role
  include Sys::Reference::Role
  include Sys::Permission

  set_permission_name "sys_users", :edit
end
