FactoryBot.define do
  factory :cms_column_select, class: Cms::Column::Select do
    cur_site { cms_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { "tooltips-#{unique_id}" }
    prefix_label { "prefix_label-#{unique_id}" }
    postfix_label { "postfix_label-#{unique_id}" }
    select_options do
      times = rand(1..5).times
      times.map { unique_id }
    end
  end
end
