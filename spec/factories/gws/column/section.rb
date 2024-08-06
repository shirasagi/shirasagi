FactoryBot.define do
  factory :gws_column_section, class: Gws::Column::Section do
    cur_site { gws_site }

    name { "section-#{unique_id}" }
    order { rand(999) }
  end
end
