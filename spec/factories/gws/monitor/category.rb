FactoryBot.define do
  factory :gws_monitor_category, class: Gws::Monitor::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    color { "#aabbcc" }
  end
end
