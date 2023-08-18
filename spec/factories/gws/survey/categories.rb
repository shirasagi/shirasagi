FactoryBot.define do
  factory :gws_survey_category, class: Gws::Survey::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "cate-#{unique_id}" }
    color { "#aabbcc" }
  end
end
