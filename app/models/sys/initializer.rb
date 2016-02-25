module Sys
  class Initializer
    Sys::Role.permission :edit_sys_sites
    Sys::Role.permission :edit_sys_groups
    Sys::Role.permission :edit_sys_users
    Sys::Role.permission :edit_sys_roles
  end
end
