FactoryGirl.define do
  factory :sys_user, class: SS::User do
    name "sys_user"
    email "sys@example.jp"
    in_password "pass"
    #sys_role_ids
  end
end
