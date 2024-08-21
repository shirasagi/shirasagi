FactoryBot.define do
  trait :gws_user_base do
    transient do
      cur_group { gws_site }
    end

    cur_site { gws_site }
    cur_user { gws_user }

    group_ids { [ cur_group.id ] }
    name { "name-#{unique_id}" }
    uid { "uid-#{unique_id}" }
    email { "#{uid}@example.jp" }
    type { SS::Model::User::TYPE_SNS }

    lang { SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s }
  end

  factory :gws_user, class: Gws::User, traits: [:gws_user_base] do
    in_password { "pass" }
  end

  factory :gws_ldap_user2, class: Gws::User, traits: [:gws_user_base] do
    name { "user2" }
    uid { "user2" }
    email { "#{uid}@example.jp" }
    type { SS::Model::User::TYPE_LDAP }
    ldap_dn { "uid=user2, ou=002001管理課, ou=002危機管理部, dc=example, dc=jp" }
  end

  factory :gws_sso_user, class: Gws::User, traits: [:gws_user_base] do
    name { unique_id }
    uid { name }
    email { "#{uid}@example.jp" }
    type { SS::Model::User::TYPE_SSO }
  end

  trait :gws_workflow_notice do
    notice_workflow_user_setting { "notify" }
    notice_workflow_email_user_setting { "notify" }
    send_notice_mail_addresses { unique_email }
  end
end
