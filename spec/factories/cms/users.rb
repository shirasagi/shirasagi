FactoryGirl.define do
  factory :cms_user_base, class: Cms::User do
    transient do
      group nil
      role nil
    end

    in_password "pass"
    group_ids { group.present? ? [group.id] : nil }
    cms_role_ids { role.present? ? [role.id] : nil }
    login_roles [SS::User::Model::LOGIN_ROLE_DBPASSWD]

    trait :cms_user_fixed_name do
      name "cms_user"
    end

    trait :cms_user_rand_name do
      name "cms_user#{unique_id}"
    end

    trait :cms_user_uid do
      uid { "#{name}" }
    end

    trait :cms_user_email do
      email { "#{name}@example.jp" }
    end

    trait :cms_user_ldap do
      login_roles [SS::User::Model::LOGIN_ROLE_DBPASSWD, SS::User::Model::LOGIN_ROLE_LDAP]
      ldap_dn { "cn=#{name},dc=example,dc=jp" }
    end

    factory :cms_user, traits: [:cms_user_fixed_name, :cms_user_uid, :cms_user_email]
    factory :cms_test_user, traits: [:cms_user_rand_name, :cms_user_uid, :cms_user_email]
    factory :cms_ldap_user, traits: [:cms_user_rand_name, :cms_user_uid, :cms_user_email, :cms_user_ldap]
  end
end
