FactoryBot.define do
  factory :gws_monitor_topic, class: Gws::Monitor::Topic do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    user_ids { [cur_user.id] }
    group_ids { cur_user.group_ids }

    trait :gws_monitor_deleted do
      deleted { Time.zone.now }
    end
  end
end
