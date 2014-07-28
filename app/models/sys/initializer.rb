# coding: utf-8
module Sys
  class Initializer
    Sys::User.addon "sys/role"
    
    Sys::Role.permission :edit_sys_sites
    Sys::Role.permission :edit_sys_users
    
  end
end
