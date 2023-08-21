FactoryBot.define do
  trait :gws_user_occupation_base do
    cur_site { gws_site }
    cur_user { gws_user }

    code { "code-#{unique_id}" }
    name { "name-#{unique_id}" }
    remark { "remark-#{unique_id}" }
  end

  trait :gws_user_occupation_random_order do
    order { rand(10_000) }
  end

  factory :gws_user_occupation, class: Gws::UserOccupation,
    traits: [:gws_user_occupation_base, :gws_user_occupation_random_order] do
  end
end
