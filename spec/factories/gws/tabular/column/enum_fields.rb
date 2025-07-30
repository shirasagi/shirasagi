FactoryBot.define do
  factory :gws_tabular_column_enum_field, class: Gws::Tabular::Column::EnumField do
    cur_site { gws_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { Array.new(rand(2..3)) { "tooltips-#{unique_id}" } }
    prefix_label { "pre-#{unique_id(2)}" }
    postfix_label { "pos-#{unique_id(2)}" }
    prefix_explanation { "<b>prefix</b>#{unique_id}" }
    postfix_explanation { "<b>postfiex</b>#{unique_id}" }
    select_options { Array.new(rand(1..5)) { "option-#{unique_id}" } }
    input_type { %w(radio checkbox select).sample }
    index_state { %w(none asc desc).sample }
  end
end
