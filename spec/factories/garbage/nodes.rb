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

  factory :garbage_node_category_list, class: Garbage::Node::CategoryList, traits: [:cms_node] do
    route "garbage/category_list"
  end

  factory :garbage_node_area, class: Garbage::Node::Area, traits: [:cms_node] do
    route "garbage/area"
  end

  factory :garbage_node_area_list, class: Garbage::Node::AreaList, traits: [:cms_node] do
    route "garbage/area_list"
  end

  factory :garbage_node_center, class: Garbage::Node::Center, traits: [:cms_node] do
    route "garbage/center"
  end

  factory :garbage_node_center_list, class: Garbage::Node::CenterList, traits: [:cms_node] do
    route "garbage/center_list"
  end

  factory :garbage_node_remark, class: Garbage::Node::Remark, traits: [:cms_node] do
    route "garbage/remark"
  end

  factory :garbage_node_remark_list, class: Garbage::Node::RemarkList, traits: [:cms_node] do
    route "garbage/remark_list"
  end
end
