FactoryBot.define do

  factory :gws_memo_category, class: Gws::Memo::Category do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
  end
end
