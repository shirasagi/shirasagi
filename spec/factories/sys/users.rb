FactoryBot.define do
  factory :sys_user, class: SS::User do
    name { "sys_user" }
    email { "sys@example.jp" }
    in_password { "pass" }
    type { SS::Model::User::TYPE_SNS }
    login_roles { [ SS::Model::User::LOGIN_ROLE_DBPASSWD ] }
    deletion_lock_state { "locked" }
    #sys_role_ids
  end

  factory :sys_user_sample, class: SS::User do
    name { unique_id.to_s }
    email { "user#{unique_id}@example.jp" }
    in_password { "pass" }
    type { SS::Model::User::TYPE_SNS }
    login_roles { [ SS::Model::User::LOGIN_ROLE_DBPASSWD ] }
    #sys_role_ids
  end
end
