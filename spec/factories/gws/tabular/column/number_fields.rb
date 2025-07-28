FactoryBot.define do
  factory :gws_tabular_column_number_field, class: Gws::Tabular::Column::NumberField do
    cur_site { gws_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { Array.new(rand(2..3)) { "tooltips-#{unique_id}" } }
    prefix_label { "pre-#{unique_id(2)}" }
    postfix_label { "pos-#{unique_id(2)}" }
    prefix_explanation { "<b>prefix</b>#{unique_id}" }
    postfix_explanation { "<b>postfiex</b>#{unique_id}" }
    field_type { %w(integer float decimal).sample }
    min_value { [ true, false ].sample ? rand(0..500) : nil }
    max_value { [ true, false ].sample ? rand(0..500) + (min_value || 0) : nil }
    default_value { [ true, false ].sample ? rand((min_value || 0)..(max_value || 500)) : nil }
    index_state { %w(none asc desc).sample }
    unique_state { %w(disabled enabled).sample }
  end
end
