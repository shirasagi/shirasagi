FactoryBot.define do
  factory :cms_column_url_field2, class: Cms::Column::UrlField2 do
    cur_site { cms_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { "tooltips-#{unique_id}" }
    prefix_label { "prefix_label-#{unique_id}" }
    postfix_label { "postfix_label-#{unique_id}" }
    html_tag { [ nil, 'a' ].sample }
  end
end
