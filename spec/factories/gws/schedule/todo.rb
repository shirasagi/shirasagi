FactoryBot.define do

  factory :gws_schedule_todo, class: Gws::Schedule::Todo do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
    member_ids { [gws_user.id] }

    todo_state 'unfinished'
  end
end
