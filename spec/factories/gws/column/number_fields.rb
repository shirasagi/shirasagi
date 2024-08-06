FactoryBot.define do
  factory :gws_column_number_field, class: Gws::Column::NumberField do
    cur_site { gws_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { Array.new(rand(3..10)) { "tooltips-#{unique_id}" } }
    prefix_label { "pre-#{unique_id(2)}" }
    postfix_label { "pos-#{unique_id(2)}" }
    prefix_explanation { "<b>prefix</b>#{unique_id}" }
    postfix_explanation { "<b>postfiex</b>#{unique_id}" }
    min_decimal { rand(10) }
    max_decimal { min_decimal + rand(10) }
    initial_decimal { (min_decimal + max_decimal) / 2 }
    scale { rand(10) }
    minus_type { %w(normal filled_triangle triangle).sample }
    place_holder { "place_holder-#{unique_id}" }
  end
end
