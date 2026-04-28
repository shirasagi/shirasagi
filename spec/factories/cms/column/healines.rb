FactoryBot.define do
  factory :cms_column_headline, class: Cms::Column::Headline do
    cur_site { cms_site }

    name { "name-#{unique_id}" }
    order { rand(999) }
    required { %w(required optional).sample }
    tooltips { "tooltips-#{unique_id}" }
    prefix_label { "pre-#{unique_id}"[0, 10] }
    postfix_label { "pos-#{unique_id}"[0, 10] }

    # Default factory simulates a legacy column (created before min/max_headline_level
    # was introduced). Tests for new-default behavior should override min/max explicitly.
    min_headline_level { nil }
    max_headline_level { nil }
  end
end
