# coding: utf-8
class Sys::Site
  include SS::Site::Model
  include Sys::Addon::Permission

  set_permission_name "sys_sites"
end
