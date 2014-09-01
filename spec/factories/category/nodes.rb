FactoryGirl.define do
  factory :category_node_base, class: Category::Node::Base, traits: [:cms_node] do
    route "category/base"
  end

  factory :category_node_node, class: Category::Node::Node, traits: [:cms_node] do
    route "category/node"
  end

  factory :category_node_page, class: Category::Node::Page, traits: [:cms_node] do
    route "category/page"
  end
end
