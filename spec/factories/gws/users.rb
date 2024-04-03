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
    in_password { "pass" }
    type { SS::Model::User::TYPE_SNS }

    lang { SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s }
  end

  factory :gws_user, class: Gws::User, traits: [:gws_user_base]
end
