FactoryBot.define do
  factory :sys_role, class: Sys::Role do
    cur_user { ss_user }
    name { "sys_role" }
    permissions { %w(edit_sys_users) }
    #permission_level 1
  end

  factory :sys_role_general, class: Sys::Role do
    cur_user { ss_user }
    name { "sys_role_general" }
    permissions { %w(use_cms use_gws use_webmail) }
    #permission_level 1
  end

  factory :sys_role_admin, class: Sys::Role do
    name { "sys_role_admin" }
    permissions { Sys::Role.permission_names }
  end

  factory :sys_role_cms, class: Sys::Role do
    cur_user { ss_user }
    name { "sys_role_cms" }
    permissions { %w(use_cms) }
  end

  factory :sys_role_gws, class: Sys::Role do
    cur_user { ss_user }
    name { "sys_role_gws" }
    permissions { %w(use_gws) }
  end

  factory :sys_role_webmail, class: Sys::Role do
    cur_user { ss_user }
    name { "sys_role_webmail" }
    permissions { %w(use_webmail) }
  end
end
