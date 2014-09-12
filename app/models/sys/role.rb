# coding: utf-8
class Sys::Role
  include SS::Role::Model
  include Sys::Addon::Permission

  set_permission_name "sys_users"

  field :permissions, type: SS::Extensions::Array

  validates :permissions, presence: true
end
