FactoryGirl.define do
  factory :cms_part, class: Cms::Part, traits: [:ss_site, :ss_user] do
    sequence(:name) { |n| "name#{n}" }
    sequence(:filename) { |n| "file#{n}.part.html" }
    route "cms/free"
    mobile_view  :show
  end
  
  trait :cms_part do
    sequence(:name) { |n| "name-#{unique_id}" }
    sequence(:filename) { |n| "dir-#{unique_id}" }
  end
  
  factory :cms_part_base, class: Cms::Part::Base, traits: [:ss_site, :ss_user, :cms_part] do
    route "cms/base"
  end
  
  factory :cms_part_free, class: Cms::Part::Free, traits: [:ss_site, :ss_user, :cms_part] do
    route "cms/free"
  end
  
  factory :cms_part_node, class: Cms::Part::Node, traits: [:ss_site, :ss_user, :cms_part] do
    route "cms/node"
  end
  
  factory :cms_part_page, class: Cms::Part::Page, traits: [:ss_site, :ss_user, :cms_part] do
    route "cms/page"
  end
  
  factory :cms_part_tabs, class: Cms::Part::Tabs, traits: [:ss_site, :ss_user, :cms_part] do
    route "cms/tabs"
  end
  
  factory :cms_part_crumb, class: Cms::Part::Crumb, traits: [:ss_site, :ss_user, :cms_part] do
    route "cms/crumb"
  end
end
