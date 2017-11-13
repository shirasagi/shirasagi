FactoryGirl.define do
  factory :gws_monitor_topic, class: Gws::Monitor::Topic do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }

    trait :attend_group_ids do
      #attend_group_ids [3]
      attend_group_ids { gws_user.group_ids }
    end

    trait :article_deleted do
      deleted Time.zone.now
    end

    trait :gws_monitor_topics do
      attend_group_ids { gws_user.group_ids }
      readable_group_ids { gws_user.group_ids }
      state "public"
    end

    trait :gws_monitor_topics_item2 do
      attend_group_ids { gws_user.group_ids + [999] }
      readable_group_ids { gws_user.group_ids + [999] }
      spec_config "0"
      state "public"
    end

    trait :gws_monitor_topics_item3 do
      attend_group_ids { gws_user.group_ids + [999] }
      readable_group_ids { gws_user.group_ids + [999] }
      spec_config "5"
      state "public"
    end

    trait :gws_monitor_answers do
      attend_group_ids { gws_user.group_ids }
      readable_group_ids { gws_user.group_ids }
      state_of_the_answers_hash { { gws_user.group_ids.first.to_s => "answered" } }
      state "public"
    end

    trait :gws_monitor_answers_item2 do
      attend_group_ids { gws_user.group_ids + [999] }
      readable_group_ids { gws_user.group_ids + [999] }
      state_of_the_answers_hash { { gws_user.group_ids.first.to_s => "answered" } }
      spec_config "0"
      state "public"
    end

    trait :gws_monitor_answers_item3 do
      attend_group_ids { gws_user.group_ids + [999] }
      readable_group_ids { gws_user.group_ids + [999] }
      state_of_the_answers_hash { { gws_user.group_ids.first.to_s => "answered" } }
      spec_config "5"
      state "public"
    end

    trait :gws_monitor_admins do
      attend_group_ids { gws_user.group_ids }
    end

    trait :gws_monitor_admins_item2 do
      attend_group_ids { gws_user.group_ids + [999] }
      readable_group_ids { gws_user.group_ids + [999] }
      state_of_the_answers_hash { { gws_user.group_ids.first.to_s => "answered" } }
      spec_config "0"
      state "public"
    end

    trait :gws_monitor_management_topics do
      attend_group_ids { gws_user.group_ids }
    end

    trait :gws_monitor_management_trashes do
      attend_group_ids { gws_user.group_ids }
      deleted Time.zone.now
    end
  end
end
