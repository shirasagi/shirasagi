FactoryBot.define do
  factory :cms_column_toc, class: Cms::Column::Toc do
    cur_site { cms_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { "optional" }
    tooltips { "tooltips-#{unique_id}" }
  end
end
