FactoryBot.define do
  factory :ss_site, class: SS::Site do
    name "ss"
    host "test-ss"
    domains "test-ss.com"
    #group_id 1
  end

  factory :ss_site_subdir, class: Cms::Site do
    name { unique_id }
    host { name }
    domains "test-ss.com"
    auto_keywords "disabled"
    auto_description "disabled"
    subdir { unique_id }
  end
end
