FactoryGirl.define do
  factory :sys_user, class: SS::User do
    name "sys_user"
    email "sys@example.jp"
    in_password "pass"
    #sys_role_ids
  end

  factory :sys_user_sample, class: SS::User do
    name { unique_id.to_s }
    email { "user#{unique_id}@example.jp" }
    in_password "pass"
    #sys_role_ids
  end
end
