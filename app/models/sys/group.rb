# coding: utf-8
class Sys::Group
  include SS::Group::Model
  include Sys::Addon::Permission
  
  set_permission_name "sys_users"
end
