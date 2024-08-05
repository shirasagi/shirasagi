FactoryBot.define do
  factory :gws_column_title, class: Gws::Column::Title do
    cur_site { gws_site }

    name { "title-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { Array.new(rand(3..10)) { "tooltips-#{unique_id}" } }
    prefix_label { "pre-#{unique_id(2)}" }
    postfix_label { "pos-#{unique_id(2)}" }
    prefix_explanation { "<b>prefix</b>#{unique_id}" }
    postfix_explanation { "<b>postfiex</b>#{unique_id}" }
    title { "title-#{unique_id}" }
    explanation { "explanation-#{unique_id}" }
  end
end
