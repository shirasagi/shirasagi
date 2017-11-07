FactoryGirl.define do
  factory :gws_monitor_topic, class: Gws::Monitor::Topic do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    #text { "text-#{unique_id}" }
    attend_group_ids { [gws_user.id] }

    #todo_state 'unfinished'
  end
end
