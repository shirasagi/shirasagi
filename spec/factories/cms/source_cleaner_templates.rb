FactoryBot.define do
  factory :cms_source_cleaner_template, class: Cms::SourceCleanerTemplate do
    cur_site { site || cms_site }
    name { "name-#{unique_id}" }
    target_type { %w(tag attribute string regexp).sample }
    target_value { "target_value-#{unique_id}" }
    action_type { %w(remove replace).sample }
    replaced_value { "replace_value-#{unique_id}" }
  end
end
