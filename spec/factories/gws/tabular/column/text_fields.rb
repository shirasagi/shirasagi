FactoryBot.define do
  factory :gws_tabular_column_text_field, class: Gws::Tabular::Column::TextField do
    cur_site { gws_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { Array.new(rand(2..3)) { "tooltips-#{unique_id}" } }
    prefix_label { "pre-#{unique_id(2)}" }
    postfix_label { "pos-#{unique_id(2)}" }
    prefix_explanation { "<b>prefix</b>#{unique_id}" }
    postfix_explanation { "<b>postfiex</b>#{unique_id}" }
    input_type { %w(single multi multi_html).sample }
    max_length { [ true, false ].sample ? rand(400..500) : nil }
    i18n_default_value_translations do
      if [ true, false ].sample
        i18n_translations(prefix: "default")
      end
    end
    validation_type { %w(none email tel url color).sample }
    i18n_state { %w(disabled enabled).sample }
    index_state { %w(none asc desc).sample }
    unique_state { %w(disabled enabled).sample }
  end
end
