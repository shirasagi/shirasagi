module Sys
  class Initializer
    Sys::Role.permission :edit_sys_sites
    Sys::Role.permission :edit_sys_users
  end
end
