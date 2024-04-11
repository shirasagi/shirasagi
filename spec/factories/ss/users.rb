FactoryBot.define do
  factory :ss_user, class: SS::User do
    name { "ss_user" }
    email { "ss@example.jp" }
    in_password { "pass" }
    type { SS::Model::User::TYPE_SNS }
    #group_ids [1]

    lang { I18n.locale.to_s }
  end

  factory :ss_user2, class: SS::User do
    name { "user2" }
    email { "user2@example.jp" }
    in_password { "pass" }
    type { SS::Model::User::TYPE_SNS }

    lang { SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s }
  end

  factory :ss_user3, class: SS::User do
    name { "user3" }
    email { "user3@example.jp" }
    in_password { "pass" }
    type { SS::Model::User::TYPE_SNS }

    lang { SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s }
  end

  factory :ss_user4, class: SS::User do
    name { "user4" }
    email { "user4@example.jp" }
    in_password { "pass" }
    type { SS::Model::User::TYPE_SNS }

    lang { SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s }
  end

  factory :ss_ldap_user2, class: SS::User do
    name { "user2" }
    uid { "user2" }
    email { "user2@example.jp" }
    type { SS::Model::User::TYPE_LDAP }
    ldap_dn { "uid=user2, ou=002001管理課, ou=002危機管理部, dc=example, dc=jp" }

    lang { SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s }
  end
end
