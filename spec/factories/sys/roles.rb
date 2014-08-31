FactoryGirl.define do
  factory :sys_role, class: Sys::Role do
    sequence(:name) { |n| "name#{n}" }
    permissions ["edit_sys_users"]
    #permission_level 1
  end
end
