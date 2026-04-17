FactoryBot.define do
  factory :cms_loop_setting, class: Cms::LoopSetting do
    transient do
      site { nil }
    end

    cur_site { site || cms_site }
    name { "name-#{unique_id}" }
    description { "description-#{unique_id}" }
    order { rand(10..20) }
    html { "html-#{unique_id}" }
    html_format { "shirasagi" }
    loop_html_setting_type { "template" }
    state { "public" }

    trait :liquid do
      html_format { "liquid" }
    end

    trait :shirasagi do
      html_format { "shirasagi" }
    end

    trait :template_type do
      loop_html_setting_type { "template" }
    end

    trait :snippet_type do
      loop_html_setting_type { "snippet" }
    end
  end
end
