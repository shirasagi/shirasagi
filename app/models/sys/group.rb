class Sys::Group
  include SS::Model::Group
  include Sys::Permission
  include Contact::Addon::Group

  set_permission_name "sys_users", :edit

  attr_accessor :sys_role_ids
  permit_params :sys_role_ids

  def users
    SS::User.in(group_ids: id)
  end
end
