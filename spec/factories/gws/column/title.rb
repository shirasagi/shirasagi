FactoryBot.define do
  factory :gws_column_title, class: Gws::Column::Title do
    cur_site { gws_site }

    name { "title-#{unique_id}" }
    order { rand(999) }
    title { "title-#{unique_id}" }
    explanation { "explanation-#{unique_id}" }
  end
end
