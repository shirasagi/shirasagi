FactoryGirl.define do
  factory :sys_role, class: Sys::Role do
    user_id { ss_user.id }
    name "sys_role"
    permissions ["edit_sys_users"]
    #permission_level 1
  end

  factory :sys_user_role, class: Sys::Role do
    name "sys_user_role"
    permissions %w(edit_sys_users edit_sys_sites)
  end
end
