FactoryBot.define do
  factory :cms_column_text_field, class: Cms::Column::TextField do
    cur_site { cms_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { "tooltips-#{unique_id}" }
    prefix_label { "pre-#{unique_id}"[0, 10] }
    postfix_label { "pos-#{unique_id}"[0, 10] }
    input_type { %w(text email tel).sample }
  end
end
