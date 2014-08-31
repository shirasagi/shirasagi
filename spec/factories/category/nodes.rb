FactoryGirl.define do
  factory :category_node_base, class: Category::Node::Base, traits: [:ss_site, :ss_user, :cms_node] do
    route "category/base"
  end

  factory :category_node_node, class: Category::Node::Node, traits: [:ss_site, :ss_user, :cms_node] do
    route "category/node"
  end

  factory :category_node_page, class: Category::Node::Page, traits: [:ss_site, :ss_user, :cms_node] do
    route "category/page"
  end
end
