FactoryBot.define do
  factory :cms_michecker_result, class: Cms::Michecker::Result do
    cur_site { cms_site }
    name { Cms::Michecker::Result::TASK_NAME }
    target_class { Cms::Michecker::Result.name }
    target_id { unique_id }
  end
end
