FactoryGirl.define do
  factory :gws_monitor_topic, class: Gws::Monitor::Topic do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }

    trait :attend_group_ids do
      attend_group_ids [1]
    end
  end
end
