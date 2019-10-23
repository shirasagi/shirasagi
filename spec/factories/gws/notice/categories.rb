FactoryBot.define do
  factory :gws_notice_category, class: Gws::Notice::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    color { "#aabbcc" }
    readable_setting_range "public"
  end
end
