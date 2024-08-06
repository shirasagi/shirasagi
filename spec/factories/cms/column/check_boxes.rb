FactoryBot.define do
  factory :cms_column_check_box, class: Cms::Column::CheckBox do
    transient do
      select_option_count { nil }
    end

    cur_site { cms_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { "tooltips-#{unique_id}" }
    prefix_label { "pre-#{unique_id}"[0, 10] }
    postfix_label { "pos-#{unique_id}"[0, 10] }
    select_options do
      count = select_option_count || rand(1..5)
      Array.new(count) { unique_id * 2 }
    end
  end
end
