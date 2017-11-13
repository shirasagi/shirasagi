FactoryGirl.define do
  factory :gws_circular_post, class: Gws::Circular::Post do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }

    trait :member_ids do
      #member_ids [3]
      member_ids { [gws_user.id] }
    end

    trait :due_date do
      due_date Time.zone.tomorrow
    end

    trait :gws_monitor_topics do
      attend_group_ids { gws_user.group_ids }
      readable_group_ids { gws_user.group_ids }
      state "public"
    end
    #
    # trait :gws_monitor_topics_item2 do
    #   attend_group_ids { gws_user.group_ids + [999] }
    #   readable_group_ids { gws_user.group_ids + [999] }
    #   spec_config "0"
    #   state "public"
    # end
    #
    # trait :gws_monitor_topics_item3 do
    #   attend_group_ids { gws_user.group_ids + [999] }
    #   readable_group_ids { gws_user.group_ids + [999] }
    #   spec_config "5"
    #   state "public"
    # end
    #
    # trait :gws_monitor_answers do
    #   attend_group_ids { gws_user.group_ids }
    #   readable_group_ids { gws_user.group_ids }
    #   state_of_the_answers_hash { { gws_user.group_ids.first.to_s => "answered" } }
    #   state "public"
    # end
    #
    # trait :gws_monitor_answers_item2 do
    #   attend_group_ids { gws_user.group_ids + [999] }
    #   readable_group_ids { gws_user.group_ids + [999] }
    #   state_of_the_answers_hash { { gws_user.group_ids.first.to_s => "answered" } }
    #   spec_config "0"
    #   state "public"
    # end
    #
    # trait :gws_monitor_answers_item3 do
    #   attend_group_ids { gws_user.group_ids + [999] }
    #   readable_group_ids { gws_user.group_ids + [999] }
    #   state_of_the_answers_hash { { gws_user.group_ids.first.to_s => "answered" } }
    #   spec_config "5"
    #   state "public"
    # end
    #
    # trait :gws_monitor_admins do
    #   attend_group_ids { gws_user.group_ids }
    # end
    #
    # trait :gws_monitor_admins_item2 do
    #   attend_group_ids { gws_user.group_ids + [999] }
    #   readable_group_ids { gws_user.group_ids + [999] }
    #   state_of_the_answers_hash { { gws_user.group_ids.first.to_s => "answered" } }
    #   spec_config "0"
    #   state "public"
    # end
    #
    # trait :gws_monitor_management_topics do
    #   attend_group_ids { gws_user.group_ids }
    # end
    #
    # trait :gws_monitor_management_trashes do
    #   attend_group_ids { gws_user.group_ids }
    #   deleted Time.zone.now
    # end
  end
end
