FactoryBot.define do
  factory :workflow_user_base, class: Cms::User do
    transient do
      group nil
      role nil
    end

    in_password "pass"
    group_ids { group.present? ? [group.id] : nil }
    cms_role_ids { role.present? ? [role.id] : nil }
    login_roles [SS::Model::User::LOGIN_ROLE_DBPASSWD]

    trait :workflow_user_fixed_name do
      name "workflow_user"
    end

    trait :workflow_user_rand_name do
      name { "workflow_user#{unique_id}" }
    end

    trait :workflow_user_uid do
      uid { name.to_s }
    end

    factory :workflow_user, traits: [:workflow_user_fixed_name, :workflow_user_uid]
    factory :workflow_test_user, traits: [:workflow_user_rand_name, :workflow_user_uid]
  end
end
