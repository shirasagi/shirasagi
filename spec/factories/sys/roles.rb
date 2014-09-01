FactoryGirl.define do
  factory :sys_role, class: Sys::Role do
    user_id { create(:ss_user).id }
    name "#{unique_id}"
    permissions ["edit_sys_users"]
    #permission_level 1
  end
end
