FactoryBot.define do
  factory :sys_user, class: SS::User do
    name { "sys_user" }
    email { "sys@example.jp" }
    in_password { "pass" }
    type { SS::Model::User::TYPE_SNS }
    deletion_lock_state { "locked" }
    #sys_role_ids

    lang { SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s }
  end

  factory :sys_user_sample, class: SS::User do
    name { unique_id.to_s }
    email { "user#{unique_id}@example.jp" }
    in_password { "pass" }
    type { SS::Model::User::TYPE_SNS }
    #sys_role_ids

    lang { SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s }
  end
end
