FactoryBot.define do
  factory :cms_task, class: Cms::Task do
    cur_site { cms_site }
    name { "cms:task" }
  end
end
