FactoryBot.define do
  factory :garbage_node_base, class: Garbage::Node::Base, traits: [:cms_node] do
    route "garbage/base"
  end

  factory :garbage_node_node, class: Garbage::Node::Node, traits: [:cms_node] do
    route "garbage/node"
  end

  factory :garbage_node_page, class: Garbage::Node::Page, traits: [:cms_node] do
    route "garbage/page"
  end

  factory :garbage_node_search, class: Garbage::Node::Search, traits: [:cms_node] do
    route "garbage/search"
  end

  factory :garbage_node_category, class: Garbage::Node::Category, traits: [:cms_node] do
    route "garbage/category"
  end
end
