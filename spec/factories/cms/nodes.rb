FactoryGirl.define do
  factory :cms_node, class: Cms::Node, traits: [:ss_site, :ss_user] do
    sequence(:name) { |n| "name-#{unique_id}" }
    sequence(:filename) { |n| "dir-#{unique_id}" }
    route "cms/node"
    shortcut :show
  end
  
  trait :cms_node do
    sequence(:name) { |n| "name-#{unique_id}" }
    sequence(:filename) { |n| "dir-#{unique_id}" }
  end
  
  factory :cms_node_base, class: Cms::Node::Base, traits: [:ss_site, :ss_user, :cms_node] do
    route "cms/base"
  end

  factory :cms_node_node, class: Cms::Node::Node, traits: [:ss_site, :ss_user, :cms_node] do
    route "cms/node"
  end

  factory :cms_node_page, class: Cms::Node::Page, traits: [:ss_site, :ss_user, :cms_node] do
    route "cms/page"
  end
end
