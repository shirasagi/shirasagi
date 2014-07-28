# coding: utf-8
class Sys::User
  include SS::User::Model
  include Sys::Addon::Permission
  
  set_permission_name "sys_users"
end
