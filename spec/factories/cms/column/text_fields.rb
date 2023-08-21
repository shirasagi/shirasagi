FactoryBot.define do
  factory :cms_column_text_field, class: Cms::Column::TextField do
    cur_site { cms_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { "tooltips-#{unique_id}" }
    prefix_label { "prefix_label-#{unique_id}" }
    postfix_label { "postfix_label-#{unique_id}" }
    input_type { %w(text email tel).sample }
  end
end
