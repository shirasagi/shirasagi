FactoryGirl.define do
  trait :cms_node do
    site_id { cms_site.id }
    user_id { cms_user.id }
    name "#{unique_id}"
    filename "#{unique_id}"
    route "cms/node"
  end

  factory :cms_node, class: Cms::Node, traits: [:cms_node] do
    shortcut :show
  end

  factory :cms_node_base, class: Cms::Node::Base, traits: [:cms_node] do
    route "cms/base"
  end

  factory :cms_node_node, class: Cms::Node::Node, traits: [:cms_node] do
    route "cms/node"
  end

  factory :cms_node_page, class: Cms::Node::Page, traits: [:cms_node] do
    route "cms/page"
  end
end
