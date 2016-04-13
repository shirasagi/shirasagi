FactoryGirl.define do
  trait :gws_user_title_base do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "title-#{unique_id}" }
  end

  trait :gws_user_title_random_order do
    order { rand(10000) }
  end

  factory :gws_user_title, class: Gws::UserTitle, traits: [:gws_user_title_base, :gws_user_title_random_order] do
  end
end
