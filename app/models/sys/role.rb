class Sys::Role
  include SS::Role::Model
  include Sys::Permission

  set_permission_name "sys_users", :edit

  field :permissions, type: SS::Extensions::Array

  validates :permissions, presence: true
end
