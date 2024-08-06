FactoryBot.define do
  factory :gws_column_text_field, class: Gws::Column::TextField do
    cur_site { gws_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { Array.new(rand(3..10)) { "tooltips-#{unique_id}" } }
    prefix_label { "pre-#{unique_id(2)}" }
    postfix_label { "pos-#{unique_id(2)}" }
    prefix_explanation { "<b>prefix</b>#{unique_id}" }
    postfix_explanation { "<b>postfiex</b>#{unique_id}" }
    input_type { %w(text email tel).sample }
    place_holder { "place_holder-#{unique_id}" }
  end
end
