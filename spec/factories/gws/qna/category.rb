FactoryBot.define do
  factory :gws_qna_category, class: Gws::Qna::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    color { "#aabbcc" }
  end
end
