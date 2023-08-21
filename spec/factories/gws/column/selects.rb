FactoryBot.define do
  factory :gws_column_select, class: Gws::Column::Select do
    cur_site { gws_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { Array.new(rand(3..10)) { "tooltips-#{unique_id}" } }
    prefix_label { "prefix_label-#{unique_id}" }
    postfix_label { "postfix_label-#{unique_id}" }
    select_options { Array.new(rand(1..5)) { "select-#{unique_id}" } }
  end
end
