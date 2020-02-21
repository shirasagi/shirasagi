FactoryBot.define do
  factory :gws_contrast, class: Gws::Contrast do
    cur_site { gws_site }

    name { "name-#{unique_id}" }
    order { rand(0..10) }
    state { %w(public closed).sample }
    text_color { "#888888" }
    color { "#333333" }
  end
end
