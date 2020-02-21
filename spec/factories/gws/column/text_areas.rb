FactoryBot.define do
  factory :gws_column_text_area, class: Gws::Column::TextArea do
    cur_site { gws_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { Array.new(rand(3..10)) { "tooltips-#{unique_id}" } }
    prefix_label { "prefix_label-#{unique_id}" }
    postfix_label { "postfix_label-#{unique_id}" }
    place_holder { "place_holder-#{unique_id}" }
  end
end
