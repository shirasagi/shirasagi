FactoryBot.define do
  factory :gws_circular_comment, class: Gws::Circular::Comment do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }
  end
end
